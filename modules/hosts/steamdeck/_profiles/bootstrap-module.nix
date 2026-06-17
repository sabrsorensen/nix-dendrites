{
  inputs,
  lib,
  host,
  steamdeck,
}:
bootMode:
{ ... }:
let
  mkBaseModule = import ./base-module.nix { inherit host; };
  isDualBoot = bootMode == "dual";
  steamUser = host.users.steam.name;
  returnToGamingEntry = {
    name = "Return to Gaming Mode";
    exec = "qdbus org.kde.Shutdown /Shutdown logout";
    icon = "steam";
    terminal = false;
    categories = [ "System" ];
    comment = "Logout and return to Steam";
  };
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
    (steamdeck.mkHwConfig bootMode)
    (steamdeck.mkSteamModule { inherit steamUser; })
    steamdeck-system
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
      xdg.desktopEntries.return-to-gaming = returnToGamingEntry;
      home.file."Desktop/return-to-gaming.desktop".text = ''
        [Desktop Entry]
        Name=${returnToGamingEntry.name}
        Exec=${returnToGamingEntry.exec}
        Icon=${returnToGamingEntry.icon}
        Terminal=${if returnToGamingEntry.terminal then "true" else "false"}
        Type=Application
        Categories=${builtins.concatStringsSep ";" returnToGamingEntry.categories};
        Comment=${returnToGamingEntry.comment}
      '';
    };
  };
}
