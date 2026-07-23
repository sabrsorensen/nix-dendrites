{ config, inputs, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
  hostModule = {
    networking.hostName = "Naboo";

    my.host = {
      name = "Naboo";
      formFactor = "server";
      roles = {
        server = true;
        rpi = true;
      };
      services = {
        blocky = true;
        dhcpCoredns = true;
      };
    };
    my.deployment = {
      enableRemoteUser = true;
      authorizedKeyFiles = [
        "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/naboo_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/naboo_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/naboo_nix.pub"
      ];
    };
    my.dhcpCoredns = {
      startKeaOnBoot = false;
      localDomainApexIp = network.atlasuponraiden;
      failover = {
        enable = true;
        peerName = "Nevarro";
        peerIp = network.nevarro;
      };
    };
    my.blocky.prometheus.enable = true;
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
  flake.nixosConfigurations.naboo = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      hostModule
    ];
  };
  flake.nixosConfigurations."naboo-image" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      hostModule
      imageModule
    ];
  };
}
