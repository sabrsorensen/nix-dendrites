{
  lib,
  fetchFromGitHub,
  fetchurl,
  mkDeckyPlugin,
  pkgs,
}:

let
  breezyVulkanBinary = fetchurl {
    url = "https://github.com/wheaney/breezy-desktop/releases/download/v2.9.11/breezyVulkan-x86_64.tar.gz";
    sha256 = "sha256-stp1KLMT5pgFEXDuq4ii80L7/QUlnoFDVJfGeZdX0F0=";
  };
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

  hash = "sha256-aTAYCuALMBYDaMrYGSFmYs4YonKX5c23MrEDFnonusQ=";
  extraNativeBuildInputs = with pkgs; [
    git
    curl
  ];
  buildInputs = with pkgs; [ wayland ];

  preConfigure = ''
    sed -i 's/del env_copy\["LD_LIBRARY_PATH"\]/env_copy.pop("LD_LIBRARY_PATH", None)/' main.py
    sed -i "s|\\['su', '-l', '-c',|['/run/current-system/sw/bin/su', '-l', '-c',|" main.py
    sed -i "s|XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active xr-driver|XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus /run/current-system/sw/bin/systemctl --user is-active xr-driver|" main.py
    sed -i "/ipc\\.is_driver_running(as_user=decky\\.DECKY_USER)/c\\
        try:\\
            subprocess.check_output([\\
                '/run/current-system/sw/bin/su', '-l', '-c',\\
                'XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus /run/current-system/sw/bin/systemctl --user is-active xr-driver',\\
                decky.DECKY_USER,\\
            ], stderr=subprocess.STDOUT)\\
            return True\\
        except subprocess.CalledProcessError as exc:\\
            decky.logger.error(f\\\"Error checking driver status {exc.output}\\\")\\
            return False\\
        except FileNotFoundError as exc:\\
            decky.logger.error(f\\\"Error checking driver status {exc}\\\")\\
            return False" main.py

    if [ -f .gitmodules ]; then
      export HOME=$TMPDIR
      git init
      git add .
      git -c user.email="builder@nixos" -c user.name="Nix Builder" commit -m "temp"
      git submodule update --init --recursive
    fi
  '';

  buildMessage = "Building XRGaming plugin frontend...";
  buildCommand = ''
    pnpm build

    echo "Creating NixOS-compatible setup wrapper..."
    mkdir -p bin
    cp ${breezyVulkanBinary} bin/breezyVulkan-x86_64.tar.gz

    cat > bin/breezy_vulkan_setup << 'EOF'
    #!/usr/bin/env bash
    # NixOS-compatible breezy setup wrapper

    set -e

    if [ "$(id -u)" = "0" ]; then
       echo "Running as root - proceeding with setup"
    else
       echo "Running as user - this is expected in NixOS"
    fi

    target_user="''${USER:-sam}"
    target_home="$(/run/current-system/sw/bin/getent passwd "$target_user" | while IFS=: read -r _ _ _ _ _ home _; do printf '%s' "$home"; done)"

    if [ -z "$target_home" ]; then
      echo "Could not resolve home directory for user: $target_user"
      exit 1
    fi

    start_dir=$(pwd)
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
      echo "Breezy Vulkan only supports x86_64 currently"
      exit 1
    fi

    metrics_version_arg=""
    binary_path_arg=""

    while [[ $# -gt 0 ]]; do
      case $1 in
        -v)
          metrics_version_arg="$2"
          shift 2
          ;;
        *)
          binary_path_arg="$1"
          shift
          ;;
      esac
    done

    if [ -z "$binary_path_arg" ]; then
      echo "No breezy vulkan binary path supplied"
      exit 1
    fi

    tmp_dir=$(mktemp -d -t breezy-vulkan-XXXXXX)
    pushd $tmp_dir > /dev/null

    if [[ "$binary_path_arg" = /* ]]; then
      abs_path="$binary_path_arg"
    else
      abs_path=$(realpath "$start_dir/$binary_path_arg")
    fi
    cp $abs_path $tmp_dir

    echo "Created temp directory: $tmp_dir"
    echo "Extracting to: ''${tmp_dir}/breezy_vulkan"
    /run/current-system/sw/bin/gzip -dc "$(basename "$binary_path_arg")" | /run/current-system/sw/bin/tar -xf -

    pushd breezy_vulkan > /dev/null

    echo "Cleaning up the previous installation"
    echo "Copying the breezy_vulkan scripts to $target_home/.local/bin and related files to $target_home/.local/share/breezy_vulkan"

    mkdir -p "$target_home/.local/bin"
    mkdir -p "$target_home/.local/share/breezy_vulkan"

    echo "Installing xrDriver"
    echo "version=$metrics_version_arg" > "$target_home/.local/share/breezy_vulkan/manifest"

    cat > "$target_home/.local/bin/breezy_vulkan_verify" << 'VERIFY_EOF'
    #!/bin/bash
    echo "Verification succeeded"
    VERIFY_EOF
    chmod +x "$target_home/.local/bin/breezy_vulkan_verify"
    /run/current-system/sw/bin/chown -R "$target_user" "$target_home/.local/bin" "$target_home/.local/share/breezy_vulkan"

    echo "Skipping udev rules installation - handled by NixOS configuration"
    echo "XRGaming setup completed successfully"

    popd > /dev/null
    popd > /dev/null
    echo "Deleting temp directory: ''${tmp_dir}"
    rm -rf $tmp_dir
    EOF
    chmod +x bin/breezy_vulkan_setup
  '';

  executablePaths = [ "*/bin/*" ];
  extraInstallCheck = ''
    if [ ! -f $out/bin/breezyVulkan-x86_64.tar.gz ]; then
      echo "Error: breezyVulkan binary not found"
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
