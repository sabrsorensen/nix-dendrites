{ config, inputs, ... }:
let
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
  hostModule = {
    networking.hostName = "nixpi";

    my.host = {
      name = "NixPi";
      formFactor = "server";
      roles.rpi = true;
    };
  };
  imageModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix") ];
      sdImage = {
        compressImage = false;
        expandOnBoot = true;
      };
      image.baseName = lib.mkDefault "${config.networking.hostName}-nixos-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
    };
  bootstrapModule = {
    networking.hostName = "nixpi";
    my.host = {
      name = "NixPi";
      formFactor = "server";
      tags = [ "bootstrap" ];
      bootstrap.finalConfigName = "nixpi";
      roles.rpi = true;
    };
    users.users.sam = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
      ];
      openssh.authorizedKeys.keyFiles = [
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/kamino.pub"
      ];
    };
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    virtualisation.docker.enable = false;
    virtualisation.podman.enable = false;
  };
  bootstrapImageModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix") ];
      sdImage = {
        compressImage = false;
        expandOnBoot = true;
      };
      image.baseName = lib.mkDefault "${config.networking.hostName}-bootstrap-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
    };
in
{
  flake.nixosConfigurations.nixpi = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      hostModule
    ];
  };
  flake.nixosConfigurations."nixpi-image" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      hostModule
      imageModule
    ];
  };
  flake.nixosConfigurations."nixpi-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      bootstrapModule
    ];
  };
  flake.nixosConfigurations."nixpi-bootstrap-image" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      bootstrapModule
      bootstrapImageModule
    ];
  };
}
