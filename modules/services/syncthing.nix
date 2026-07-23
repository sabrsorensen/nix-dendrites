{ inputs, ... }:
let
  topology = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/syncthing/sam.json");
  mkDevice = name: id: {
    inherit name id;
    addresses = [ "dynamic" ];
  };
  serverDevices = [ "AtlasUponRaiden" ];
  desktopDevices = [
    "Kamino"
    "ZaphodBeeblebrox"
  ];
  mobileDevices = [ "No-phone" ];
  gamingDevices = [
    "EmeraldEcho"
    "EmeraldEchoSteamOS"
  ];
  nonGamingDevices = serverDevices ++ desktopDevices ++ mobileDevices;
  folderPaths = {
    "3DPrinting" = "3d_printing";
    MobileDownloads = "mobile_downloads";
  };
  folderLabels = {
    "3DPrinting" = "3D Printing";
    MobileDownloads = "Mobile Downloads";
  };
  mkFolder = name: devices: {
    id = topology.folderIds.${name};
    label = folderLabels.${name} or name;
    path = "/home/sam/${folderPaths.${name} or name}/";
    inherit devices;
    type = "sendreceive";
    versioning = {
      type = "simple";
      params.keep = "10";
    };
  };
in
{
  flake.modules.nixos.syncthing =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.syncthing;
      homeClient = builtins.elem config.my.host.name [
        "Kamino"
        "ZaphodBeeblebrox"
        "EmeraldEcho"
      ];
      filteredFolders = lib.filterAttrs (
        _: folder: builtins.elem config.networking.hostName folder.devices
      ) cfg.folders;
      defaultFolders = {
        "3DPrinting" = mkFolder "3DPrinting" nonGamingDevices;
        Downloads = mkFolder "Downloads" (serverDevices ++ desktopDevices);
        gen_sync = mkFolder "gen_sync" nonGamingDevices;
        MobileDownloads = mkFolder "MobileDownloads" (mobileDevices ++ serverDevices ++ desktopDevices);
        NewMusic = mkFolder "NewMusic" nonGamingDevices;
        NoMansSky = mkFolder "NoMansSky" (serverDevices ++ desktopDevices ++ gamingDevices);
        SteamPipe = mkFolder "SteamPipe" (serverDevices ++ desktopDevices ++ gamingDevices);
        StardewValley = mkFolder "StardewValley" (
          serverDevices ++ desktopDevices ++ mobileDevices ++ gamingDevices ++ [ "LavenderHaze" ]
        );
      };
    in
    {
      options.my.syncthing = {
        serverUser = lib.mkOption {
          type = lib.types.str;
          default = "sam";
        };
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
        };
        configDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        devices = lib.mkOption {
          type = lib.types.attrs;
          default = builtins.mapAttrs mkDevice topology.deviceIds;
        };
        folders = lib.mkOption {
          type = lib.types.attrs;
          default = defaultFolders;
        };
      };
      config = lib.mkMerge [
        (lib.mkIf config.my.host.services.syncthing {
          sops.secrets.syncthing_gui_password = {
            owner = cfg.serverUser;
            group = cfg.serverUser;
            mode = "0400";
            sopsFile = "${inputs.nix-secrets}/secrets.yaml";
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
          # The predecessor managed these clients through Home Manager while
          # retaining Atlas as the sole system-managed instance.
          services.syncthing.openDefaultPorts = true;
          home-manager.users.sam = {
            sops.defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
            sops.secrets.syncthing_gui_password = { };
            services.syncthing = {
              enable = true;
              guiCredentials = {
                passwordFile = config.home-manager.users.sam.sops.secrets.syncthing_gui_password.path;
                username = "sam";
              };
              overrideDevices = false;
              overrideFolders = false;
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
              tray = {
                enable = config.my.host.name != "EmeraldEcho";
                package = pkgs.syncthingtray;
              };
            };
            home.packages = lib.optionals config.my.host.roles.steamdeck [ pkgs.syncthingtray ];
          };
        })
      ];
    };
}
