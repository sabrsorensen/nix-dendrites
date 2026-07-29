{ config, inputs, ... }:
let
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
  hostModule = {
    networking.hostName = "Nevarro";

    # Keep local aarch64 builds from exhausting RAM without adding SD-card
    # write amplification from a disk-backed swap file.
    zramSwap = {
      enable = true;
      memoryPercent = 100;
    };

    my.host = {
      name = "Nevarro";
      formFactor = "server";
      platform = "rpi";
      home.enable = true;
      roles = {
        server = true;
      };
      services = {
        blocky = true;
        dhcpCoredns = true;
      };
    };
    my.deployment = {
      enableRemoteUser = true;
      authorizedKeyFiles = [
        "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/nevarro_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/nevarro_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/nevarro_nix.pub"
      ];
    };
    my.blocky.prometheus.enable = true;
    my.dhcpCoredns.localDomainApexIp =
      (builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json")).atlasuponraiden;
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
in
{
  flake.nixosConfigurations.nevarro = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      hostModule
    ];
  };
  flake.nixosConfigurations."nevarro-image" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      hostModule
      imageModule
    ];
  };
}
