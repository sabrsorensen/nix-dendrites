{
  inputs,
  lib,
  shared,
}:
bootMode:
{
  config,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  isDualBoot = bootMode == "dual";
  diskConfigFile =
    if isDualBoot then "steamdeck-dualboot-disk-config.nix" else "steamdeck-singleboot-disk-config.nix";
  diskConfigPath =
    if isDualBoot then
      ../_steamdeck/disk-configs/steamdeck-dualboot-disk-config.nix
    else
      ../_steamdeck/disk-configs/steamdeck-singleboot-disk-config.nix;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.jovian-nixos.nixosModules.default
    (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
    (import ../_steamdeck/steamdeck-hw-config.nix bootMode)
    (import ../_steamdeck/steamdeck-steam.nix { steamUser = shared.steamUser; })
    ../_steamdeck/steamdeck-system.nix
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = lib.mkForce "jovian-installer";

  users.users.nixos.enable = lib.mkForce false;
  services.displayManager.autoLogin.user = lib.mkForce shared.installerUser;
  jovian = {
    decky-loader.enable = lib.mkForce false;
    steam = {
      autoStart = lib.mkForce false;
      user = lib.mkForce shared.installerUser;
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
          src = shared.root;
          filter =
            path: _type:
            let
              rootStr = toString shared.root;
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

  users.users.${shared.installerUser} = {
    isNormalUser = true;
    description = "Steam Deck Installer User";
    extraGroups = shared.steamUserExtraGroups;
    password = "jovian";
    shell = pkgs.bash;
  }
  // lib.optionalAttrs isDualBoot {
    uid = 1000;
  };

  users.groups.${shared.installerUser} = lib.optionalAttrs isDualBoot {
    gid = 1000;
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh.settings = {
    PermitRootLogin = lib.mkForce "yes";
    PermitEmptyPasswords = "yes";
  };
  services.flatpak.enable = lib.mkForce false;

  environment.etc.${diskConfigFile}.text = lib.readFile diskConfigPath;

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.grub.efiSupport = lib.mkForce false;

  documentation.enable = false;
  documentation.nixos.enable = false;
}
