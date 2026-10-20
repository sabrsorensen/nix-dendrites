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
    "Pabu"
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
  mkFolder = homeDirectory: name: devices: {
    id = topology.folderIds.${name};
    label = folderLabels.${name} or name;
    path = "${homeDirectory}/${folderPaths.${name} or name}/";
    inherit devices;
    ignorePatterns = [ ];
    type = "sendreceive";
    versioning = {
      type = "simple";
      params.keep = "10";
    };
  };
  mkDefaultFolders =
    homeDirectory:
    let
      mkFolder' = mkFolder homeDirectory;
    in
    {
      "3DPrinting" = mkFolder' "3DPrinting" nonGamingDevices;
      Downloads = mkFolder' "Downloads" (serverDevices ++ desktopDevices);
      gen_sync = mkFolder' "gen_sync" nonGamingDevices;
      MobileDownloads = mkFolder' "MobileDownloads" (mobileDevices ++ serverDevices ++ desktopDevices);
      NewMusic = mkFolder' "NewMusic" nonGamingDevices;
      NoMansSky = mkFolder' "NoMansSky" (
        serverDevices ++ desktopDevices ++ gamingDevices ++ mobileDevices
      );
      ReturnToMoria = mkFolder' "ReturnToMoria" (
        serverDevices ++ desktopDevices ++ gamingDevices ++ mobileDevices ++ [ "LavenderHaze" ]
      );
      SteamPipe = mkFolder' "SteamPipe" (serverDevices ++ desktopDevices ++ gamingDevices);
      StardewValley = mkFolder' "StardewValley" (
        serverDevices ++ desktopDevices ++ mobileDevices ++ gamingDevices ++ [ "LavenderHaze" ]
      );
    };
  devices = builtins.mapAttrs mkDevice topology.deviceIds;
  homeModule = import ./_syncthing-home.nix { inherit inputs; };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.syncthing = homeModule;

  # Topology defaults for standalone Home Manager (e.g. SteamOS), where there
  # is no NixOS `my.syncthing` to pass devices/folders through.
  flake.modules.homeManager.syncthing-topology =
    { config, lib, ... }:
    {
      my.syncthingClient = {
        devices = lib.mkDefault devices;
        folders = lib.mkDefault (mkDefaultFolders config.home.homeDirectory);
      };
    };

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
          default = devices;
        };
        folders = lib.mkOption {
          type = lib.types.attrs;
          default = mkDefaultFolders "/home/${cfg.serverUser}";
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
