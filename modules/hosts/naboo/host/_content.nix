{ inputs, network }:
{
  hostModule = {
    networking.hostName = "Naboo";
    zramSwap = {
      enable = true;
      memoryPercent = 100;
    };
    my.host = {
      name = "Naboo";
      address = network.naboo;
      formFactor = "server";
      platform = "rpi";
      home.enable = true;
      roles.server = true;
      services = {
        blocky = true;
        dhcpCoredns = true;
        monitoringExporters = true;
      };
    };
    networking.nameservers = [
      network.nevarro
      "1.1.1.1"
      "9.9.9.9"
    ];
    users.users.sam.openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/naboo.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino/naboo.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/naboo.pub"
    ];
    my.deployment = {
      enableRemoteUser = true;
      localFlakePath = "/home/sam/src/nix-dendrites";
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
}
