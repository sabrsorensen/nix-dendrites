{
  inputs,
  lib,
  ...
}:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib network; };
in
descriptorHelpers.mkRpiDescriptor {
  name = "Naboo";
  outputName = "naboo";
  hostName = "Naboo";
  configuration = "Naboo";
  network = {
    mode = "static";
    address = network.naboo;
    nameservers = [
      network.nevarro
      "1.1.1.1"
      "9.9.9.9"
    ];
  };
  deploy = {
    method = "secure";
    secure.peer = {
      name = "Nevarro";
      ip = network.nevarro;
    };
  };
  services = {
    roles = [
      "blocky-dns"
      "dhcp-standby"
    ];
    imports = with inputs.self.modules.nixos; [
      blocky
      dhcp-coredns
    ];
    blocky.enable = true;
    blocky.prometheus.enable = true;
    dhcpCoredns = {
      localDomainApexIp = network.atlasuponraiden;
      failoverPeer = {
        name = "Nevarro";
        ip = network.nevarro;
      };
      startKeaOnBoot = false;
    };
  };
  outputs.image = {
    enable = true;
    name = "NabooImage";
    outputName = "naboo-image";
    configuration = "NabooImage";
  };
  users.primary = {
    name = "sam";
    ssh = {
      identityFile = "~/.ssh/naboo_id_ed25519";
      nixIdentityFile = "~/.ssh/nix_naboo_id_ed25519";
    };
    authorizedKeys = {
      sam = [
        "atlasuponraiden/naboo"
        "kamino/naboo"
        "zaphodbeeblebrox/naboo"
      ];
      nixRemote = [
        "atlasuponraiden/naboo_nix"
        "kamino/naboo_nix"
        "zaphodbeeblebrox/naboo_nix"
      ];
    };
  };
  myHost = {
    primaryInteractiveUser = "sam";
    formFactor = "server";
    roles = {
      server = true;
      rpi = true;
      serviceHost = true;
    };
  };
  # Give local Nix builds headroom without writing a swap file to the SD card.
  config.zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
  config.services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    openFirewall = true;
    enabledCollectors = [
      "hwmon"
      "systemd"
    ];
  };
  config.services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = "0.0.0.0";
    openFirewall = true;
  };
}
