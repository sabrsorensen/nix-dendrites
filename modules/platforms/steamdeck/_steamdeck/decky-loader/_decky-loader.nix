{
  config,
  pkgs,
  ...
}:
let
  runtimeLibraryPath = pkgs.lib.makeLibraryPath (
    with pkgs;
    [
      glibc
      stdenv.cc.cc.lib
      zlib
      openssl
    ]
  );
  # Jovian ships Decky Loader 3.2.8, which sets PATH alongside LD_LIBRARY_PATH in
  # localplatformlinux's `run` default env; only the systemd/python3 absolute-path
  # patches remain necessary.
  deckyLoaderPackage = pkgs.decky-loader.overridePythonAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace backend/decky_loader/localplatform/localplatformlinux.py \
        --replace-fail '["systemctl", "is-active", service_name]' '["${pkgs.systemd}/bin/systemctl", "is-active", service_name]' \
        --replace-fail '["systemctl", "daemon-reload"]' '["${pkgs.systemd}/bin/systemctl", "daemon-reload"]' \
        --replace-fail '["systemctl", "restart", service_name]' '["${pkgs.systemd}/bin/systemctl", "restart", service_name]' \
        --replace-fail '["systemctl", "stop", service_name]' '["${pkgs.systemd}/bin/systemctl", "stop", service_name]' \
        --replace-fail '["systemctl", "start", service_name]' '["${pkgs.systemd}/bin/systemctl", "start", service_name]'
      substituteInPlace backend/decky_loader/helpers.py \
        --replace-fail '["python3" if localplatform.ON_LINUX else "python", "-c",' '["${pkgs.python3}/bin/python3" if localplatform.ON_LINUX else "python", "-c",' \
        --replace-fail 'env={} if localplatform.ON_LINUX else None' 'env={"PATH": os.environ.get("PATH", "")} if localplatform.ON_LINUX else None'
    '';
  });
  steamCefDebugScript = pkgs.writeShellScript "steam-cef-debug" ''
    set -eu
    if [ -e "$HOME/.steam/steam" ]; then
      steam_root="$HOME/.steam/steam"
    elif [ -d "$HOME/.local/share/Steam" ]; then
      steam_root="$HOME/.local/share/Steam"
    else
      exit 0
    fi
    test -e "$steam_root/.cef-enable-remote-debugging" || touch "$steam_root/.cef-enable-remote-debugging"
  '';
in
{
  jovian.decky-loader = {
    enable = true;
    package = deckyLoaderPackage;
    user = "sam";
    extraPackages = with pkgs; [
      # Scripts extracted from a plugin's own vendored tarballs at runtime
      # (e.g. XR Gaming's breezy_vulkan/xr_driver setup chain) keep their
      # original `#!/usr/bin/env bash` shebang -- Nix's patchShebangs only
      # ever sees files present at build time. `env` needs bash on PATH.
      bash
      coreutils
      hidapi
      psmisc
      python3
      steam-run
      systemd
      # None of these are otherwise on decky-loader's PATH (its systemd unit
      # gets an explicit PATH built only from this list, not
      # /run/current-system/sw/bin). All are needed by XR Gaming's vendored
      # breezy_vulkan/xr_driver setup chain, not reimplemented by us:
      # curl is hard-required (xr_driver/setup's check_command "curl"),
      # getent/gnutar resolve the target user and extract the vendored
      # tarballs, gzip and jq are used optionally in the same chain, kmod
      # provides lsmod for the uinput kernel module check, and procps
      # provides `ps` for xr_driver/setup's own systemd-detection check
      # (`ps -p 1 -o comm=`) -- without it that check silently fails closed
      # and the script wrongly concludes systemd isn't running and aborts.
      curl
      getent
      gnutar
      gzip
      jq
      kmod
      procps
      # unifideck's Edge-based OAuth/xCloud flow (auth/edge_browser/detection.py)
      # probes `shutil.which("microsoft-edge")`/`"microsoft-edge-stable"` on the
      # decky-loader process's own PATH before falling back to installing the
      # `com.microsoft.Edge` flatpak itself. Providing it here means Epic/GOG
      # login and xCloud work without the plugin doing its own flatpak install.
      # nixpkgs' package installs its `mainProgram` as `microsoft-edge`, which
      # matches the first name unifideck searches for.
      microsoft-edge
      # unifideck's shared prefix_clone.py shells out to `rsync` (plain
      # subprocess, no absolute path) to clone a game's base Proton prefix
      # onto a picked storage location -- confirmed live: installing a
      # Battle.net game to external storage failed with
      # `FileNotFoundError: [Errno 2] No such file or directory: 'rsync'`
      # and the abandoned-prefix cleanup log right after it, since rsync
      # isn't on decky-loader's PATH otherwise (same closed-PATH situation
      # documented on every other extraPackages entry here).
      rsync
      # unifideck's GOGStore shells out to `gogdl` (GOG's own downloader,
      # vendored from Heroic Games Launcher) via BinaryResolver, whose
      # System PATH tier is a plain `shutil.which("gogdl")` -- confirmed
      # live: GOG sign-in failed with the backend logging
      # "[BinaryResolver] gogdl not found in any tier" /
      # "[GOGStore] gogdl unavailable -- reporting store as unavailable"
      # on every attempt, since it isn't on decky-loader's PATH otherwise
      # (same closed-PATH situation as every other extraPackages entry
      # here). nixpkgs' gogdl is 1.3.0, matching binary_signatures.py's
      # own pinned expectation exactly.
      gogdl
    ];
    extraPythonPackages =
      pythonPackages: with pythonPackages; [
        click
        vdf
      ];
  };
  environment.systemPackages = with pkgs; [
    python3
    # unifideck's browser-OAuth flow (Epic/GOG/Amazon/Microsoft sign-in)
    # doesn't run inside decky-loader's own process -- signing in launches
    # a non-Steam shortcut ("<store>:<game-key>-auth-temp-...") that Steam
    # runs in its own gamescope session, under the ordinary system PATH,
    # not decky-loader's extraPackages-scoped one. Confirmed live: the
    # per-launch log (~/.local/share/unifideck/launches/*.log) for a GOG
    # sign-in attempt got as far as
    # "[Edge] Session env detected from PID ... (steam): DISPLAY=..."
    # and then just stopped -- no error, no browser window -- because
    # `microsoft-edge` (already in decky-loader's own extraPackages,
    # above) wasn't reachable from *this* process's PATH at all. Having
    # it here too, system-wide, is what the launcher subprocess actually
    # needs; decky-loader's own copy stays for its own internal checks
    # (see that entry's comment).
    microsoft-edge
  ];
  nixpkgs.config.permittedInsecurePackages = [ "pnpm-9.15.9" ];
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      glibc
      zlib
      openssl
      libgcc
    ];
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="3318", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="32e9", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04e8", ATTRS{idProduct}=="a007", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="16d3", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="30a6", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0486", ATTRS{idProduct}=="5740", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0486", ATTRS{idProduct}=="5744", MODE="0664", GROUP="plugdev"
    KERNEL=="uinput", MODE="0664", GROUP="input"
    # XR Gaming's vendored xr_driver ships these same rules under
    # /etc/udev/rules.d, but that's a symlink into the read-only Nix store
    # on any NixOS system -- writing there always fails, so it never
    # actually took effect at runtime. Declare them here instead.
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1bbb", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d2", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="35ca", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", KERNEL=="hiddev[0-9]*", ATTRS{idVendor}=="35ca", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", ATTRS{idVendor}=="35ca", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="hidraw", KERNEL=="hidraw[0-9]*", ATTRS{idVendor}=="35ca", MODE="0664", GROUP="plugdev"
  '';
  systemd.services.steam-cef-debug = {
    description = "Seed Steam CEF debugging toggle for Decky Loader";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.jovian.steam.user;
      ExecStart = steamCefDebugScript;
    };
  };
  systemd.services.decky-loader.environment = {
    LD_LIBRARY_PATH = runtimeLibraryPath;
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${
      toString config.users.users.${config.jovian.steam.user}.uid
    }/bus";
    DBUS_SYSTEM_BUS_ADDRESS = "unix:path=/run/dbus/system_bus_socket";
  };
  # `su` is a NixOS security wrapper, not a plain package -- it only exists
  # at /run/wrappers/bin/su, so extraPackages (which only ever adds
  # <pkg>/bin dirs) can't reach it. XR Gaming's vendored xr_driver/setup
  # calls bare `su` to drop from root to the target user.
  systemd.services.decky-loader.path = [ "/run/wrappers" ];
}
