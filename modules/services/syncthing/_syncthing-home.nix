{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.syncthingClient;
  filteredFolders = lib.filterAttrs (
    _: folder: builtins.elem cfg.hostName folder.devices
  ) cfg.folders;
in
{
  options = {
    my.features.syncthing = lib.mkEnableOption "Syncthing desktop client";
    my.syncthingClient = {
      hostName = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      devices = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
      folders = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
      tray.enable = lib.mkEnableOption "Syncthing tray icon";
      isSteamDeck = lib.mkEnableOption "Steam Deck Syncthing client behavior";
    };
  };

  config = lib.mkIf config.my.features.syncthing {
    assertions = [
      {
        assertion = cfg.hostName != "";
        message = "Syncthing client configuration requires my.syncthingClient.hostName.";
      }
    ];
    sops.defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
    sops.secrets.syncthing_gui_password = { };
    services.syncthing = {
      enable = true;
      guiCredentials = {
        passwordFile = config.sops.secrets.syncthing_gui_password.path;
        username = config.home.username;
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
        enable = cfg.tray.enable;
        package = pkgs.syncthingtray;
      };
    };
    home.packages = lib.optionals cfg.isSteamDeck [ pkgs.syncthingtray ];
  };
}
