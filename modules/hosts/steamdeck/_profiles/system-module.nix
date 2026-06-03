{
  inputs,
  lib,
  host,
}:
bootMode:
{ config, pkgs, ... }:
let
  mkBaseModule = import ./base-module.nix { inherit host; };
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
    ../_platform/decky/decky-plugins.nix
    (import ../_platform/decky/steamdeck-decky.nix { steamUser = host.steamUser; })
    ../_platform/decky/steamdeck-plugins.nix
    (import ../_platform/steamdeck/steamdeck-hw-config.nix bootMode)
    (import ../_platform/steamdeck/steamdeck-steam.nix { steamUser = host.steamUser; })
    ../_platform/steamdeck/steamdeck-system.nix
  ];
  extraConfig = {
    my.host.deploy.enableRemoteUser = true;

    users.users.${host.steamUser} = {
      isNormalUser = true;
      extraGroups = host.steamUserExtraGroups;
      uid = lib.mkForce 1000;
      hashedPasswordFile = config.sops.secrets.hashed_password.path;
      openssh.authorizedKeys.keyFiles = host.steamUserAuthorizedKeys;
    };

    users.groups.${host.steamUser}.gid = lib.mkForce 1000;

    users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
      openssh.authorizedKeys.keyFiles = host.nixRemoteAuthorizedKeys;
    };

    home-manager.users.${host.steamUser}.imports = [
      inputs.self.modules.homeManager.${host.primaryHostName}
      ../_platform/steamdeck/steamdeck-shortcut.nix
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
