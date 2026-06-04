{
  inputs,
  lib,
  host,
}:
bootMode:
{ ... }:
let
  mkBaseModule = import ./base-module.nix { inherit host; };
  isDualBoot = bootMode == "dual";
  steamUser = host.users.steam.name;
in
mkBaseModule {
  inherit bootMode;
  lifecycle = "bootstrap";
  extraImports = with inputs.self.modules.nixos; [
    system-minimal
    home-manager
    ssh
    firmware
    cli-tools
    locale
    disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.jovian-nixos.nixosModules.default
    (import ../_platform/steamdeck/steamdeck-hw-config.nix bootMode)
    (import ../_platform/steamdeck/steamdeck-steam.nix { inherit steamUser; })
    ../_platform/steamdeck/steamdeck-system.nix
  ];
  extraConfig = {
    services.openssh.settings = {
      PasswordAuthentication = lib.mkForce true;
      KbdInteractiveAuthentication = lib.mkForce false;
    };

    users.users.${steamUser} = {
      isNormalUser = true;
      extraGroups = host.users.steam.extraGroups;
      hashedPasswordFile = lib.mkForce null;
      initialPassword = "jovian";
    }
    // lib.optionalAttrs isDualBoot {
      uid = lib.mkForce 1000;
    };

    users.groups.${steamUser} = lib.optionalAttrs isDualBoot {
      gid = lib.mkForce 1000;
    };

    home-manager.users.${steamUser} = {
      home.username = steamUser;
      home.homeDirectory = "/home/${steamUser}";
      home.stateVersion = "26.05";
      imports = [ ../_platform/steamdeck/steamdeck-shortcut.nix ];
    };
  };
}
