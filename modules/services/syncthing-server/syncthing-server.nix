{
  flake.modules.nixos.syncthing-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hostName = config.networking.hostName;

      # Import the same device/folder definitions that Home Manager uses
      allDevices = config.my.syncthing.devices;
      allFolders = config.my.syncthing.folders;
      filteredFolders = lib.filterAttrs (_: folder: builtins.elem hostName folder.devices) allFolders;
    in
    {
      options.my.syncthing = {
        enable = lib.mkEnableOption "NixOS server Syncthing configuration";

        serverUser = lib.mkOption {
          type = lib.types.str;
          default = "sam";
          description = "User to run Syncthing as on the server";
        };

        devices = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Syncthing device definitions keyed by device name.";
        };

        folders = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Syncthing folder definitions keyed by folder name.";
        };
      };

      config = lib.mkIf config.my.syncthing.enable {
        # System service configuration - runs at boot, independent of user login
        services.syncthing = {
          enable = true;
          user = config.my.syncthing.serverUser;
          dataDir = "/home/${config.my.syncthing.serverUser}/.local/share/syncthing";
          configDir = "/home/${config.my.syncthing.serverUser}/.config/syncthing";
          openDefaultPorts = true;

          # Web GUI configuration
          guiAddress = "0.0.0.0:8384";  # Allow access from network

          settings = {
            devices = allDevices;
            folders = filteredFolders;

            options = {
              localAnnounceEnabled = true;
              urAccepted = -1;
              # Disable QUIC to work around quic-go v0.56.0 TLS bug
              connectionPriorityQuicLan = 0;
              connectionPriorityQuicWan = 0;
              # Force TCP-only mode to completely avoid QUIC
              listenAddresses = [ "tcp://:22000" ];
              # Disable crash reporting to avoid startup delays
              crashReportingEnabled = false;
            };
          };
        };

        # Optional: Set up GUI credentials via sops (if available)
        # services.syncthing.guiCredentials = {
        #   username = config.my.syncthing.serverUser;
        #   passwordFile = config.sops.secrets.syncthing_gui_password.path;
        # };

        # Ensure the user exists and has appropriate permissions
        users.users.${config.my.syncthing.serverUser} = {
          extraGroups = [ "syncthing" ];
        };
      };
    };
}