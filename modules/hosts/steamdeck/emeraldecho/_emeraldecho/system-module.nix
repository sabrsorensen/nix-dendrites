{
  inputs,
  lib,
  shared,
}:
bootMode:
{ config, pkgs, ... }:
let
  enableNixRemote =
    !(config.wsl.enable or false) && config ? sops && config.sops.secrets ? hashed_password;
in
{
  imports = with inputs.self.modules.nixos; [
    sam
    system-cli
    disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.jovian-nixos.nixosModules.default
    ../_decky/decky-plugins.nix
    (import ../_decky/steamdeck-decky.nix { steamUser = shared.steamUser; })
    ../_decky/steamdeck-plugins.nix
    (import ../_steamdeck/steamdeck-hw-config.nix bootMode)
    (import ../_steamdeck/steamdeck-steam.nix { steamUser = shared.steamUser; })
    ../_steamdeck/steamdeck-system.nix
  ];

  users.users.${shared.steamUser} = {
    isNormalUser = true;
    extraGroups = shared.steamUserExtraGroups;
    uid = lib.mkForce 1000;
    hashedPasswordFile = config.sops.secrets.hashed_password.path;
    openssh.authorizedKeys.keyFiles = shared.steamUserAuthorizedKeys;
  };

  users.groups.${shared.steamUser}.gid = lib.mkForce 1000;

  users.users.nix-remote = lib.mkIf enableNixRemote {
    openssh.authorizedKeys.keyFiles = shared.nixRemoteAuthorizedKeys;
  };

  home-manager.users.${shared.steamUser}.imports = [
    inputs.self.modules.homeManager.EmeraldEcho
  ];

  networking.firewall.allowedTCPPorts = [
    1400
    3400
    24800
  ];
  networking.firewall.allowedUDPPorts = [ 24800 ];

  environment.systemPackages = map (name: pkgs.${name}) shared.deckSystemPackages;

  programs.kdeconnect.enable = true;
}
