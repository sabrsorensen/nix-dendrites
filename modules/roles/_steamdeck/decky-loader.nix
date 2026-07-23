{ ... }:
let
  # Jovian provides Decky's service and option surface. Keep the base role
  # limited to the upstream loader; plugin packages are separate opt-in work.
  module =
    {
      config,
      lib,
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
      deckyLoaderPackage = pkgs.decky-loader.overridePythonAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace backend/decky_loader/localplatform/localplatformlinux.py \
            --replace-fail 'env: ENV | None = {"LD_LIBRARY_PATH": ""}' \
            'env: ENV | None = {"LD_LIBRARY_PATH": "", "PATH": os.environ.get("PATH", "")}' \
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
    lib.mkIf config.my.host.is.steamdeck {
      jovian.decky-loader = {
        enable = true;
        package = deckyLoaderPackage;
        user = "sam";
        extraPackages = with pkgs; [
          coreutils
          hidapi
          psmisc
          python3
          steam-run
          systemd
        ];
        extraPythonPackages =
          pythonPackages: with pythonPackages; [
            click
            vdf
          ];
      };
      environment.systemPackages = with pkgs; [ python3 ];
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
    };
in
module
