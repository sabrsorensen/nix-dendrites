{
  flake.modules.homeManager.syncthing =
    {
      config,
      lib,
      pkgs,
      osConfig,
      inputs,
      ...
    }:
    let
      hostName = osConfig.networking.hostName;

      # Desktop/laptop hosts that should use Home Manager syncthing
      desktopHosts = [ "Kamino" "ZaphodBeeblebrox" "EmeraldEcho" ];

      # Server/headless hosts that should use NixOS syncthing-server
      serverHosts = [ "AtlasUponRaiden" ];

      # Disabled hosts (RPis, WSL) that don't need syncthing
      disabledHosts = [ "Naboo" "Nevarro" ];

      shouldEnable = builtins.elem hostName desktopHosts;
      isSteamDeck = hostName == "EmeraldEcho";
      shouldHaveTray = builtins.elem hostName [ "Kamino" "ZaphodBeeblebrox" ];

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
          warnings = lib.optionals (config.my.syncthing.enable) (
            (lib.optional (builtins.elem hostName serverHosts)
              "Syncthing enabled via Home Manager on ${hostName}, but this server host should use the NixOS syncthing-server module for always-on operation.")
            ++
            (lib.optional (builtins.elem hostName disabledHosts)
              "Syncthing enabled via Home Manager on ${hostName}, but syncthing is currently disabled for RPi/WSL hosts.")
          );
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
