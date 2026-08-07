{
  config,
  lib,
  pkgs,
  cfg,
  filteredFolders,
  homeClient,
  secretsFile,
  ...
}:
lib.mkMerge [
  (lib.mkIf config.my.host.services.syncthing {
    sops.secrets.syncthing_gui_password = {
      owner = cfg.serverUser;
      group = cfg.serverUser;
      mode = "0400";
      sopsFile = secretsFile;
    };
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
    services.syncthing = {
      enable = true;
      user = cfg.serverUser;
      dataDir =
        if cfg.dataDir != null then cfg.dataDir else "/home/${cfg.serverUser}/.local/share/syncthing";
      configDir =
        if cfg.configDir != null then cfg.configDir else "/home/${cfg.serverUser}/.config/syncthing";
      guiAddress = cfg.guiAddress;
      guiPasswordFile = config.sops.secrets.syncthing_gui_password.path;
      openDefaultPorts = true;
      settings = {
        devices = cfg.devices;
        folders = filteredFolders;
        options = {
          localAnnounceEnabled = true;
          urAccepted = -1;
          connectionPriorityQuicLan = 0;
          connectionPriorityQuicWan = 0;
          listenAddresses = [ "tcp://:22000" ];
          crashReportingEnabled = false;
        };
      };
    };
    users.users.${cfg.serverUser}.extraGroups = [ "syncthing" ];
  })
  (lib.mkIf homeClient {
    services.syncthing.openDefaultPorts = true;
  })
]
