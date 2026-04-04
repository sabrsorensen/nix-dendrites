{
  inputs,
  lib,
  shared,
}:
bootMode:
{ ... }:
let
  isDualBoot = bootMode == "dual";
in
{
  imports = with inputs.self.modules.nixos; [
    system-minimal
    home-manager
    ssh
    firmware
    cli-tools
    locale
    disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.jovian-nixos.nixosModules.default
    (import ../_steamdeck/steamdeck-hw-config.nix bootMode)
    (import ../_steamdeck/steamdeck-steam.nix { steamUser = shared.steamUser; })
    ../_steamdeck/steamdeck-system.nix
  ];

  users.users.${shared.steamUser} = {
    isNormalUser = true;
    extraGroups = shared.steamUserExtraGroups;
    hashedPasswordFile = lib.mkForce null;
    initialPassword = "jovian";
  }
  // lib.optionalAttrs isDualBoot {
    uid = lib.mkForce 1000;
  };

  users.groups.${shared.steamUser} = lib.optionalAttrs isDualBoot {
    gid = lib.mkForce 1000;
  };

  home-manager.users.${shared.steamUser} = {
    home.username = shared.steamUser;
    home.homeDirectory = "/home/${shared.steamUser}";
    home.stateVersion = "26.05";
    imports = [ ../_steamdeck/steamdeck-shortcut.nix ];
  };
}
