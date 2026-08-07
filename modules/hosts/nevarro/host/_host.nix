{ inputs, network }:
{
  hostModule = {
    networking.hostName = "Nevarro";
    zramSwap = {
      enable = true;
      memoryPercent = 100;
    };
    my.host = {
      name = "Nevarro";
      address = network.nevarro;
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
      network.naboo
      "1.1.1.1"
      "9.9.9.9"
    ];
    users.users.sam.openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/nevarro.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino/nevarro.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/nevarro.pub"
    ];
    my.deployment = {
      enableRemoteUser = true;
      localFlakePath = "/home/sam/src/nix-dendrites";
      authorizedKeyFiles = [
        "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/nevarro_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/nevarro_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/nevarro_nix.pub"
      ];
    };
    my.blocky.prometheus.enable = true;
    my.dhcpCoredns.localDomainApexIp = network.atlasuponraiden;
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
