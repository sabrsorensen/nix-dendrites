{
  inputs,
  ...
}:
{
  flake.modules.nixos.syncthing-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.syncthing.server;
      hostName = config.networking.hostName;
      syncthingCommonOptions = inputs.self.lib.shared.syncthingCommonOptions;
      serverUser = config.my.syncthing.serverUser;

      # Import the same device/folder definitions that Home Manager uses
      allDevices = config.my.syncthing.devices;
      allFolders = config.my.syncthing.folders;
      filteredFolders = lib.filterAttrs (_: folder: builtins.elem hostName folder.devices) allFolders;
    in
    {
      options.my.services.syncthing.server = {
        enable = lib.mkEnableOption "boot-time system-service Syncthing configuration";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = "syncthing";
        };

        guiAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:8384";
        };

        dataDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Syncthing data directory for the system service.";
        };

        configDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Syncthing config directory for the system service.";
        };
      };

      options.my.syncthing = {
        serverUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
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

      config = lib.mkIf cfg.enable {
        sops.secrets.syncthing_gui_password = {
          owner = serverUser;
          group = serverUser;
          mode = "0400";
        };

        assertions = [
          {
            assertion = serverUser != null;
            message = "my.syncthing.serverUser must be set, or my.host.primaryInteractiveUser must be defined, when my.services.syncthing.server.enable is set.";
          }
        ];

        my.syncthing.serverUser = lib.mkDefault config.my.host.primaryInteractiveUser;

        # System service configuration - runs at boot, independent of user login
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            handle_path /${cfg.pathSegment}/* {
              reverse_proxy http://${cfg.guiAddress} {
                header_up Host {upstream_hostport}
              }
            }
          ''
        ];
        services = {
          syncthing = {
            enable = true;
            user = serverUser;
            dataDir = if cfg.dataDir != null then cfg.dataDir else "/home/${serverUser}/.local/share/syncthing";
            configDir =
              if cfg.configDir != null then cfg.configDir else "/home/${serverUser}/.config/syncthing";
            openDefaultPorts = true;

            # Web GUI configuration
            guiAddress = cfg.guiAddress;
            guiPasswordFile = config.sops.secrets.syncthing_gui_password.path;

            settings = {
              devices = allDevices;
              folders = filteredFolders;

              options = syncthingCommonOptions;
            };
          };
        };

        # Ensure the user exists and has appropriate permissions
        users.users.${serverUser} = {
          extraGroups = [ "syncthing" ];
        };
      };
    };
}
