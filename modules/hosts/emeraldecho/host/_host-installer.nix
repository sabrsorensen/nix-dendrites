{
  inputs,
  lib,
}:
let
  mkInstallerModule =
    {
      baseModule,
      isDualBoot,
    }:
    lib.recursiveUpdate baseModule {
      nixpkgs.config.allowUnfree = true;
      networking.hostName = lib.mkForce "jovian-installer";
      my.host.tags = [
        (if isDualBoot then "steamdeck-dualboot" else "steamdeck-singleboot")
        "installer"
      ];
      my.host.home.enable = false;
      my.deployment.enableRemoteUser = false;
      home-manager.users = lib.mkForce { };
      users.users.nixos.enable = lib.mkForce false;
      users.users.sam = {
        enable = lib.mkForce false;
        isNormalUser = lib.mkForce true;
        group = lib.mkForce "sam";
      };
      users.users.jovian = {
        isNormalUser = true;
        description = "Steam Deck Installer User";
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "video"
        ];
        initialPassword = "jovian";
      };
      services.displayManager.autoLogin.user = lib.mkForce "jovian";
      services.openssh.settings = {
        PasswordAuthentication = lib.mkForce true;
        KbdInteractiveAuthentication = lib.mkForce false;
        PermitRootLogin = lib.mkForce "yes";
        PermitEmptyPasswords = "yes";
      };
      security.sudo.wheelNeedsPassword = false;
      services.flatpak.enable = lib.mkForce false;
      jovian.steam = {
        autoStart = lib.mkForce false;
        user = lib.mkForce "jovian";
        desktopSession = lib.mkForce null;
      };
      jovian.decky-loader.enable = lib.mkForce false;
      boot = {
        loader = {
          systemd-boot.enable = lib.mkForce false;
          grub = {
            enable = lib.mkForce false;
            efiSupport = lib.mkForce false;
          };
        };
        zfs.forceImportRoot = false;
      };
      documentation.enable = false;
    };
  installerIso =
    isDualBoot:
    { config, lib, ... }:
    {
      imports = [
        (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
      ];
      isoImage = {
        volumeID = if isDualBoot then "JOVIAN_DUALBOOT" else "JOVIAN_NIXOS";
        squashfsCompression = "gzip -Xcompression-level 1";
        makeEfiBootable = true;
        makeUsbBootable = true;
      };
      image.fileName = lib.mkForce "jovian-nixos-${lib.optionalString isDualBoot "dualboot-"}${config.system.nixos.label}.iso";
    };
in
{
  inherit mkInstallerModule installerIso;
}
