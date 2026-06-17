{
  inputs,
  lib,
  host,
  steamdeck,
}:
bootMode:
{ config, pkgs, ... }:
let
  mkBaseModule = import ./base-module.nix { inherit host; };
  mkSecretsSshKeyFiles = inputs.self.lib.shared.mkSecretsSshKeyFiles;
  steamUser = host.users.steam.name;
in
mkBaseModule {
  inherit bootMode;
  lifecycle = "system";
  extraImports = with inputs.self.modules.nixos; [
    samCli
    system-cli
    disko
    deploy-defaults
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.jovian-nixos.nixosModules.default
    steamdeck-decky-plugins
    (steamdeck.mkDeckyModule { inherit steamUser; })
    steamdeck-plugins
    (steamdeck.mkHwConfig bootMode)
    (steamdeck.mkSteamModule { inherit steamUser; })
    steamdeck-system
  ];
  extraConfig = {
    my.host.deploy.enableRemoteUser = true;

    users.users.${steamUser} = {
      isNormalUser = true;
      extraGroups = host.users.steam.extraGroups;
      uid = lib.mkForce 1000;
      hashedPasswordFile = config.sops.secrets.hashed_password.path;
      openssh.authorizedKeys.keyFiles = mkSecretsSshKeyFiles host.users.steam.authorizedKeyPaths;
    };

    users.groups.${steamUser}.gid = lib.mkForce 1000;

    users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
      openssh.authorizedKeys.keyFiles = mkSecretsSshKeyFiles host.users.nixRemote.authorizedKeyPaths;
    };

    home-manager.users.${steamUser}.imports = [
      inputs.self.modules.homeManager.${host.primaryHostName}
    ];

    networking.firewall.allowedTCPPorts = [
      1400
      3400
      24800
    ];
    networking.firewall.allowedUDPPorts = [ 24800 ];

    environment.systemPackages = host.systemPackages pkgs;
    services.flatpak.packages = [
      "io.github.Geocld.XStreamingDesktop"
      "io.github.unknownskl.greenlight"
    ];

    programs.kdeconnect.enable = true;
  };
}
