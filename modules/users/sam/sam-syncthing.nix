{ inputs, ... }:
{
  flake.modules.homeManager.sam-syncthing =
    { config, lib, ... }:
    let
      private = config.my.syncthing.private;
      homeDir = config.home.homeDirectory;
      mkDevice = name: id: {
        addresses = [ "dynamic" ];
        inherit id name;
      };
      mkFolder =
        {
          name,
          path,
          devices,
          id ? private.folderIds.${name},
          label ? name,
        }:
        {
          copyOwnershipFromParent = false;
          inherit
            devices
            id
            label
            path
            ;
          enable = true;
          ignorePatterns = [ ];
          type = "sendreceive";
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
      serverDevices = [ "AtlasUponRaiden" ];
      desktopDevices = [
        "Kamino"
        "ZaphodBeeblebrox"
      ];
      mobileDevices = [ "No-phone" ];
      gamingDevices = [ "EmeraldEcho" ];
      nonGamingDevices = serverDevices ++ desktopDevices ++ mobileDevices;
    in
    {
      imports = [ "${inputs.nix-secrets}/modules/sam-syncthing-universal.nix" ];

      options.my.syncthing.private = {
        deviceIds = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Private Syncthing device IDs keyed by device name.";
        };
        folderIds = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Private Syncthing folder IDs keyed by folder name.";
        };
      };

      config.my.syncthing = {
        enable = true;
        devices = lib.mapAttrs mkDevice private.deviceIds;
        folders = {
          "3DPrinting" = mkFolder {
            name = "3DPrinting";
            label = "3D Printing";
            path = "${homeDir}/3d_printing/";
            devices = nonGamingDevices;
          };
          Downloads = mkFolder {
            name = "Downloads";
            path = "${homeDir}/Downloads/";
            devices = serverDevices ++ desktopDevices;
          };
          gen_sync = mkFolder {
            name = "gen_sync";
            path = "${homeDir}/gen_sync/";
            devices = nonGamingDevices;
          };
          MobileDownloads = mkFolder {
            name = "MobileDownloads";
            label = "Mobile Downloads";
            path = "${homeDir}/mobile_downloads/";
            devices = mobileDevices ++ serverDevices ++ desktopDevices;
          };
          NewMusic = mkFolder {
            name = "NewMusic";
            path = "${homeDir}/NewMusic/";
            devices = nonGamingDevices;
          };
          NoMansSky = mkFolder {
            name = "NoMansSky";
            path = "${homeDir}/NoMansSky/";
            devices = serverDevices ++ desktopDevices ++ gamingDevices;
          };
          SteamPipe = mkFolder {
            name = "SteamPipe";
            path = "${homeDir}/SteamPipe/";
            devices = serverDevices ++ desktopDevices ++ gamingDevices;
          };
          StardewValley = mkFolder {
            name = "StardewValley";
            path = "${homeDir}/StardewValley/";
            devices = serverDevices ++ desktopDevices ++ mobileDevices ++ gamingDevices ++ [ "LavenderHaze" ];
          };
        };
      };
    };

  flake.modules.nixos.sam-syncthing =
    { config, lib, ... }:
    let
      private = config.my.syncthing.private;
      homeDir = "/home/sam";
      mkDevice = name: id: {
        addresses = [ "dynamic" ];
        inherit id name;
      };
      mkFolder =
        {
          name,
          path,
          devices,
          id ? private.folderIds.${name},
          label ? name,
        }:
        {
          copyOwnershipFromParent = false;
          inherit
            devices
            id
            label
            path
            ;
          enable = true;
          ignorePatterns = [ ];
          type = "sendreceive";
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
      serverDevices = [ "AtlasUponRaiden" ];
      desktopDevices = [
        "Kamino"
        "ZaphodBeeblebrox"
      ];
      mobileDevices = [ "No-phone" ];
      gamingDevices = [ "EmeraldEcho" ];
      nonGamingDevices = serverDevices ++ desktopDevices ++ mobileDevices;
    in
    {
      imports = [ "${inputs.nix-secrets}/modules/sam-syncthing-universal.nix" ];

      options.my.syncthing.private = {
        deviceIds = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Private Syncthing device IDs keyed by device name.";
        };
        folderIds = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Private Syncthing folder IDs keyed by folder name.";
        };
      };

      config.my.syncthing = {
        devices = lib.mapAttrs mkDevice private.deviceIds;
        folders = {
          "3DPrinting" = mkFolder {
            name = "3DPrinting";
            label = "3D Printing";
            path = "${homeDir}/3d_printing/";
            devices = nonGamingDevices;
          };
          Downloads = mkFolder {
            name = "Downloads";
            path = "${homeDir}/Downloads/";
            devices = serverDevices ++ desktopDevices;
          };
          gen_sync = mkFolder {
            name = "gen_sync";
            path = "${homeDir}/gen_sync/";
            devices = nonGamingDevices;
          };
          MobileDownloads = mkFolder {
            name = "MobileDownloads";
            label = "Mobile Downloads";
            path = "${homeDir}/mobile_downloads/";
            devices = mobileDevices ++ serverDevices ++ desktopDevices;
          };
          NewMusic = mkFolder {
            name = "NewMusic";
            path = "${homeDir}/NewMusic/";
            devices = nonGamingDevices;
          };
          NoMansSky = mkFolder {
            name = "NoMansSky";
            path = "${homeDir}/NoMansSky/";
            devices = serverDevices ++ desktopDevices ++ gamingDevices;
          };
          SteamPipe = mkFolder {
            name = "SteamPipe";
            path = "${homeDir}/SteamPipe/";
            devices = serverDevices ++ desktopDevices ++ gamingDevices;
          };
          StardewValley = mkFolder {
            name = "StardewValley";
            path = "${homeDir}/StardewValley/";
            devices = serverDevices ++ desktopDevices ++ mobileDevices ++ gamingDevices ++ [ "LavenderHaze" ];
          };
        };
      };
    };
}
