{
  inputs,
  descriptor,
  lib,
  host,
  steamdeck,
}:
bootMode:
{
  config,
  pkgs,
  ...
}:
let
  mkBaseModule = import ./base-module.nix { inherit descriptor host; };
  system = pkgs.stdenv.hostPlatform.system;
  isDualBoot = bootMode == "dual";
  steamUser = host.users.steam.name;
  installerUser = host.users.installer.name;
  diskConfigFile =
    if isDualBoot then "steamdeck-dualboot-disk-config.nix" else "steamdeck-singleboot-disk-config.nix";
  diskConfigPath =
    if isDualBoot then
      ../_platform/steamdeck/disk-configs/steamdeck-dualboot-disk-config.nix
    else
      ../_platform/steamdeck/disk-configs/steamdeck-singleboot-disk-config.nix;
in
mkBaseModule {
  inherit bootMode;
  lifecycle = "installer";
  extraImports = [
    inputs.disko.nixosModules.disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.jovian-nixos.nixosModules.default
    (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
    inputs.self.modules.nixos.host-context
    (steamdeck.mkHwConfig bootMode)
    (steamdeck.mkSteamModule { inherit steamUser; })
    inputs.self.modules.nixos.steamdeck-system
  ];
  extraConfig = {
    nixpkgs.config.allowUnfree = true;

    networking.hostName = lib.mkForce "jovian-installer";

    users.users.nixos.enable = lib.mkForce false;
    services.displayManager.autoLogin.user = lib.mkForce installerUser;
    jovian = {
      decky-loader.enable = lib.mkForce false;
      steam = {
        autoStart = lib.mkForce false;
        user = lib.mkForce installerUser;
        desktopSession = lib.mkForce null;
      };
    };

    image = {
      baseName = lib.mkForce (
        lib.concatStringsSep "-" (
          [
            "jovian"
            "nixos"
          ]
          ++ lib.optionals isDualBoot [ "dualboot" ]
          ++ [
            (lib.optionalString (config.isoImage.edition != "") config.isoImage.edition)
            config.system.nixos.label
            system
          ]
        )
      );
      fileName = lib.mkForce (config.image.baseName + ".iso");
    };

    isoImage = {
      volumeID = if isDualBoot then "JOVIAN_DUALBOOT" else "JOVIAN_NIXOS";
      squashfsCompression = "gzip -Xcompression-level 1";
      makeEfiBootable = true;
      makeUsbBootable = true;
      contents = [
        {
          source = lib.sources.cleanSourceWith {
            src = host.root;
            filter =
              path: _type:
              let
                rootStr = toString host.root;
                pathStr = toString path;
                rel = if pathStr == rootStr then "." else lib.removePrefix "${rootStr}/" pathStr;
                top = builtins.head (lib.splitString "/" rel);
              in
              rel == "."
              || builtins.elem rel [
                "flake.nix"
                "flake.lock"
              ]
              || builtins.elem top [
                "modules"
                "steamdeck-packages"
              ];
          };
          target = "nix-config";
        }
      ];
    };

    users.users.${installerUser} = {
      isNormalUser = true;
      description = "Steam Deck Installer User";
      extraGroups = host.users.steam.extraGroups;
      password = "jovian";
      shell = pkgs.bash;
    }
    // lib.optionalAttrs isDualBoot {
      uid = 1000;
    };

    users.groups.${installerUser} = lib.optionalAttrs isDualBoot {
      gid = 1000;
    };

    security.sudo.wheelNeedsPassword = false;

    services.openssh.settings = {
      PasswordAuthentication = lib.mkForce true;
      KbdInteractiveAuthentication = lib.mkForce false;
      PermitRootLogin = lib.mkForce "yes";
      PermitEmptyPasswords = "yes";
    };
    services.flatpak.enable = lib.mkForce false;

    environment.etc.${diskConfigFile}.text = lib.readFile diskConfigPath;

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.grub.enable = lib.mkForce false;
    boot.loader.grub.efiSupport = lib.mkForce false;
    boot.zfs.forceImportRoot = false;

    documentation.enable = false;
    documentation.nixos.enable = false;
  };
}
