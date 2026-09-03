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
    ignorePatterns = [ ];
    type = "sendreceive";
    versioning = {
      type = "simple";
      params.keep = "10";
    };
  };
in
{
  dendritic.homeManagerModules = [ (import ./_syncthing-home.nix { inherit inputs; }) ];

  flake.modules.nixos.syncthing =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.syncthing;
      homeClient =
        config.my.host.home.enable
        && builtins.elem config.my.host.name [
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
      options.my.host.services.syncthing = lib.mkEnableOption "system Syncthing";
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
      config = import ./_syncthing-nixos.nix (
        args
        // {
          inherit cfg filteredFolders homeClient;
          secretsFile = "${inputs.nix-secrets}/secrets.yaml";
        }
      );
    };
}
