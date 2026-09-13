{
  lib,
  fetchFromGitHub,
  fetchurl,
  mkDeckyPlugin,
  pkgs,
}:
let
  writeSourceReplacementScript = import ./_write-source-replacement-script.nix { inherit pkgs; };
  # Upstream's plugin.json declares these as `remote_binary` assets that the
  # Decky Store normally fetches at runtime. We pre-fetch them at build time
  # instead so the plugin has no runtime network dependency, but they must be
  # the exact assets from this release: main.py passes decky-XRGaming's own
  # bin/ dir as breezy_vulkan_setup's local-directory argument, and the real
  # script (vendored below, not reimplemented) looks inside it by these exact
  # filenames.
  breezyVulkanPayload = fetchurl {
    url = "https://github.com/wheaney/breezy-desktop/releases/download/v2.9.11/breezyVulkan-x86_64.tar.gz";
    sha256 = "sha256-stp1KLMT5pgFEXDuq4ii80L7/QUlnoFDVJfGeZdX0F0=";
  };
  breezyVulkanLibsPayload = fetchurl {
    url = "https://github.com/wheaney/breezy-desktop/releases/download/v2.9.11/breezyVulkan-libs-x86_64.tar.gz";
    sha256 = "sha256-A8KZPuCWpr/nXFGASemSeZli0UxdgxSD4WYnPwo9m3U=";
  };
  # The real launcher script from the same release, vendored verbatim rather
  # than reimplemented: it just extracts the two archives above into a temp
  # dir and hands off to bin/setup inside breezyVulkan-x86_64.tar.gz, which
  # does the actual driver/vkBasalt install and in turn fetches+extracts
  # xrDriver's own archives the same way. Almost none of that inner logic
  # needs patching for NixOS -- it just needs getent/curl/tar/gzip/lsmod/su
  # on PATH at runtime (see jovian.decky-loader.extraPackages) -- except one
  # thing patched below: xr_driver's own setup unconditionally falls back to
  # writing udev rules under /etc/udev/rules.d, which on any NixOS system is
  # a symlink into the read-only Nix store (udev rules are generated
  # declaratively at build time, not dropped in at runtime). That `cp`
  # always fails there, and with `set -e` it aborts the rest of setup
  # (systemd service install, uinput check, ...). The rules themselves are
  # declared instead via services.udev.extraRules in
  # _steamdeck-decky-loader.nix.
  breezyVulkanSetupScript = fetchurl {
    url = "https://github.com/wheaney/breezy-desktop/releases/download/v2.9.11/breezy_vulkan_setup";
    sha256 = "sha256-CXFThyPkpixqfyXdb7T2f5/F5GO1lmeCIVuMHr1lEOA=";
  };
  # breezyVulkanPayload with xrDriver-x86_64.tar.gz's own bundled `setup`
  # script patched (see comment above) -- unpack the outer archive, unpack
  # the nested xrDriver archive, patch it, and repack both with the same
  # internal directory names main.py's whole call chain expects.
  patchedBreezyVulkanPayload =
    pkgs.runCommand "breezyVulkan-x86_64-patched.tar.gz"
      {
        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.gzip
        ];
      }
      ''
        work=$(mktemp -d)
        cd "$work"
        tar -xzf ${breezyVulkanPayload}
        cd breezy_vulkan
        tar -xzf xrDriver-x86_64.tar.gz
        sed -i 's#cp udev/\* $UDEV_RULES_DIR#cp udev/* $UDEV_RULES_DIR || true#' xr_driver/setup
        grep -qF 'cp udev/* $UDEV_RULES_DIR || true' xr_driver/setup
        rm xrDriver-x86_64.tar.gz
        tar -czf xrDriver-x86_64.tar.gz xr_driver
        rm -rf xr_driver
        cd ..
        tar -czf "$out" breezy_vulkan
      '';

  # No escaping needed for the `$(id -u)` command substitutions: this string
  # becomes one argv element passed straight to `su -c` via
  # subprocess.check_output([...]) (a list, so no shell ever sees it before
  # su's own -c parses it) -- a stray `\$` here is a literal backslash by
  # the time su's shell parses it, which is a syntax error, not an escape.
  xrGamingDriverStatusCommand =
    "XDG_RUNTIME_DIR=/run/user/$(id -u) "
    + "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus "
    + "${pkgs.systemd}/bin/systemctl --user is-active xr-driver";

  xrGamingMainPyPatches = [
    {
      kind = "literal";
      reason = "Do not fail if LD_LIBRARY_PATH is already absent in the copied environment.";
      old = ''del env_copy["LD_LIBRARY_PATH"]'';
      new = ''env_copy.pop("LD_LIBRARY_PATH", None)'';
      minCount = 1;
      maxCount = 2;
    }
    {
      kind = "literal";
      reason = ''
        Resolve su by absolute path instead of relying on PATH: on NixOS
        `su` is a security wrapper, not a plain package -- it only exists
        at /run/wrappers/bin/su (pkgs.shadow itself doesn't ship it).
      '';
      old = "['su', '-l', '-c',";
      new = "['/run/wrappers/bin/su', '-l', '-c',";
      expectedCount = 1;
    }
    {
      kind = "regex";
      reason = "Replace Decky's helper with a NixOS-safe user-service probe.";
      pattern = ''return ipc\.is_driver_running\(as_user=decky\.DECKY_USER\)'';
      replacement = ''
        try:
                    subprocess.check_output([
                        '/run/wrappers/bin/su', '-l', '-c',
                        '${xrGamingDriverStatusCommand}',
                        decky.DECKY_USER,
                    ], stderr=subprocess.STDOUT)
                    return True
                except subprocess.CalledProcessError as exc:
                    decky.logger.error(f"Error checking driver status {exc.output}")
                    return False
                except FileNotFoundError as exc:
                    decky.logger.error(f"Error checking driver status {exc}")
                    return False'';
      expectedCount = 1;
    }
    {
      # Vendored via the PyXRLinuxDriverIPC git submodule, not upstream's own
      # main.py.
      file = "defaults/PyXRLinuxDriverIPC/xrdriveripc.py";
      kind = "literal";
      reason = ''
        write_config wrote its temp file to a relative "temp.txt" (the
        plugin's CWD, which lives in the read-only Nix store) then
        os.replace()'d it into ~/.config/xr_driver/config.ini -- an atomic
        rename across filesystems, which raises EXDEV. Write the temp file
        into the destination's own directory instead.
      '';
      old = ''
        temp_file = "temp.txt"

                    # Write to a temporary file
                    with open(temp_file, 'w') as f:
                        f.write(output)

                    # Atomically replace the old config file with the new one
                    os.makedirs(os.path.dirname(self.config_file_path), exist_ok=True)
                    os.replace(temp_file, self.config_file_path)'';
      new = ''
        os.makedirs(os.path.dirname(self.config_file_path), exist_ok=True)
                    temp_file = self.config_file_path + ".tmp"

                    # Write to a temporary file
                    with open(temp_file, 'w') as f:
                        f.write(output)

                    # Atomically replace the old config file with the new one
                    os.replace(temp_file, self.config_file_path)'';
      expectedCount = 1;
    }
  ];

  xrGamingMainPyPatchScript = writeSourceReplacementScript {
    scriptName = "decky-xrgaming-main-patches";
    defaultFile = "main.py";
    replacements = xrGamingMainPyPatches;
  };

  xrGamingBootstrapSubmodules = pkgs.writeShellScript "decky-xrgaming-bootstrap-submodules" ''
    set -eu
    if [ ! -f .gitmodules ]; then
      exit 0
    fi
    export HOME="$TMPDIR"
    git init
    git add .
    git -c user.email="builder@nixos" -c user.name="Nix Builder" commit -m "temp"
    git submodule update --init --recursive
  '';

  xrGamingBundleRuntimeAssets = pkgs.writeShellScript "decky-xrgaming-bundle-runtime-assets" ''
    set -eu
    mkdir -p bin
    cp ${patchedBreezyVulkanPayload} bin/breezyVulkan-x86_64.tar.gz
    cp ${breezyVulkanLibsPayload} bin/breezyVulkan-libs-x86_64.tar.gz
    install -m 0755 ${breezyVulkanSetupScript} bin/breezy_vulkan_setup
  '';
in
mkDeckyPlugin {
  pname = "decky-XRGaming";
  version = "1.5.4";
  src = fetchFromGitHub {
    owner = "wheaney";
    repo = "decky-XRGaming";
    rev = "646d431c19cb361c91cd3adf10a91d9ca886feda";
    sha256 = "sha256-YEsCMfWR4ohXBhhyqVYrwhs5j49OuBFxahTaYarRv/o=";
    fetchSubmodules = true;
  };
  hash = "sha256-USsFNT8+c2ekBcShzdkjaq5980ctDwK8LYKp8wOoFIw=";
  extraNativeBuildInputs = with pkgs; [
    git
    curl
  ];
  buildInputs = with pkgs; [ wayland ];
  sourceReplacementScript = xrGamingMainPyPatchScript;
  preConfigure = ''
    ${xrGamingBootstrapSubmodules}
  '';
  buildMessage = "Building XRGaming plugin frontend...";
  postBuild = ''
    ${xrGamingBundleRuntimeAssets}
  '';
  executablePaths = [ "*/bin/*" ];
  extraInstallCheck = ''
    if [ ! -f $out/bin/breezyVulkan-x86_64.tar.gz ]; then
      echo "Error: breezyVulkan binary not found"
      exit 1
    fi
    if [ ! -f $out/bin/breezyVulkan-libs-x86_64.tar.gz ]; then
      echo "Error: breezyVulkan libs archive not found"
      exit 1
    fi
  '';
  meta = with lib; {
    description = "Decky plugin for XR Gaming with VR headset support";
    homepage = "https://github.com/wheaney/decky-XRGaming";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
