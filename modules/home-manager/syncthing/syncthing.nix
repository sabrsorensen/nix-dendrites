{
  flake.modules.homeManager.syncthing =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    let
      hostName = osConfig.networking.hostName;
      isSteamDeck = hostName == "EmeraldEcho";
      disableTray = builtins.elem hostName [
        "AtlasUponRaiden"
        "EmeraldEcho"
        "Naboo"
        "Nevarro"
      ];

      allDevices = config.my.syncthing.devices;
      allFolders = config.my.syncthing.folders;
      filteredFolders = lib.filterAttrs (_: folder: builtins.elem hostName folder.devices) allFolders;
    in
    {
      options.my.syncthing = {
        enable = lib.mkEnableOption "Home Manager Syncthing configuration";

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
        services.syncthing = {
          enable = true;
          guiAddress = "0.0.0.0:8384";
          overrideDevices = false;
          overrideFolders = false;
          settings = {
            devices = allDevices;
            folders = filteredFolders;
            options.localAnnounceEnabled = true;
          };
          tray = {
            enable = !disableTray;
            package = pkgs.syncthingtray;
          };
        };

        home.packages = lib.optionals isSteamDeck [ pkgs.syncthingtray ];
      };
    };
}
