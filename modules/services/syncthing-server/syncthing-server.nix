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
      hostName = config.networking.hostName;
      syncthingCommonOptions = inputs.self.lib.shared.syncthingCommonOptions;
      serverUser = config.my.syncthing.serverUser;

      # Import the same device/folder definitions that Home Manager uses
      allDevices = config.my.syncthing.devices;
      allFolders = config.my.syncthing.folders;
      filteredFolders = lib.filterAttrs (_: folder: builtins.elem hostName folder.devices) allFolders;
    in
    {
      options.my.syncthing = {
        enable = lib.mkEnableOption "NixOS server Syncthing configuration";

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

      config = lib.mkIf config.my.syncthing.enable {
        sops.secrets.syncthing_gui_password = {
          owner = serverUser;
          group = serverUser;
          mode = "0400";
        };

        assertions = [
          {
            assertion = serverUser != null;
            message = "my.syncthing.serverUser must be set, or my.host.primaryInteractiveUser must be defined, when Syncthing server mode is enabled.";
          }
        ];

        my.syncthing.serverUser = lib.mkDefault config.my.host.primaryInteractiveUser;

        # System service configuration - runs at boot, independent of user login
        my.caddy.apexRoutes = [
          ''
            redir /syncthing /syncthing/
            handle_path /syncthing/* {
              reverse_proxy http://127.0.0.1:8384 {
                header_up Host {upstream_hostport}
              }
            }
          ''
        ];
        services = {
          syncthing = {
            enable = true;
            user = serverUser;
            dataDir = "/home/${serverUser}/.local/share/syncthing";
            configDir = "/home/${serverUser}/.config/syncthing";
            openDefaultPorts = true;

            # Web GUI configuration
            guiAddress = "127.0.0.1:8384";
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
