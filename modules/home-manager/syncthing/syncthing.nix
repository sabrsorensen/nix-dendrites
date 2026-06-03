{
  flake.modules.homeManager.syncthing =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      hostCfg =
        if osConfig ? my && osConfig.my ? host then osConfig.my.host else config.my.host;
      hostName = hostCfg.name;
      isSteamDeck = hostCfg.roles.steamdeck;
      shouldEnable = hostCfg.syncthing.mode == "home";
      shouldWarnServer = hostCfg.syncthing.mode == "system";
      shouldHaveTray = hostCfg.syncthing.hasTray;

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

      # Show a warning if enabled on a host that should use system service
      config = lib.mkMerge [
        {
          warnings = lib.optionals (config.my.syncthing.enable && shouldWarnServer) [
            "Syncthing enabled via Home Manager on ${hostName}, but this host declares system-managed Syncthing."
          ];
        }
        (lib.mkIf (config.my.syncthing.enable && shouldEnable) {
        services.syncthing = {
          enable = true;
          #guiAddress = "0.0.0.0:8384";
          guiCredentials = {
            passwordFile = config.sops.secrets.syncthing_gui_password.path;
            username = config.home.username;
          };
          overrideDevices = false;
          overrideFolders = false;
          settings = {
            devices = allDevices;
            folders = filteredFolders;
            #gui = {
            #  theme = "black";
            #  user = config.home.username;
            #};
            options = {
              localAnnounceEnabled = true;
              urAccepted = -1;
              # Disable QUIC to work around quic-go v0.56.0 TLS bug
              # that causes "crypto/tls bug: where's my session ticket?" panics
              connectionPriorityQuicLan = 0;
              connectionPriorityQuicWan = 0;
              # Force TCP-only mode to completely avoid QUIC
              listenAddresses = [ "tcp://:22000" ];
              # Disable crash reporting to avoid startup delays
              crashReportingEnabled = false;
            };
          };
          tray = {
            enable = shouldHaveTray;
            package = pkgs.syncthingtray;
          };
        };

        home.packages = lib.optionals isSteamDeck [ pkgs.syncthingtray ];
        })
      ];
    };
}
