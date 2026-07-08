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
  name = "Nevarro";
  outputName = "nevarro";
  hostName = "Nevarro";
  configuration = "Nevarro";
  network = {
    mode = "static";
    address = network.nevarro;
    nameservers = [
      network.naboo
      "1.1.1.1"
      "9.9.9.9"
    ];
  };
  deploy = {
    method = "secure";
    secure.peer = {
      name = "Naboo";
      ip = network.naboo;
    };
  };
  services = {
    roles = [
      "blocky-dns"
      "dhcp-primary"
    ];
    imports = with inputs.self.modules.nixos; [
      blocky
      dhcp-coredns
    ];
    blocky.enable = true;
    blocky.prometheus.enable = true;
    dhcpCoredns.localDomainApexIp = network.atlasuponraiden;
  };
  outputs.image = {
    enable = true;
    name = "NevarroImage";
    outputName = "nevarro-image";
    configuration = "NevarroImage";
  };
  users.primary = {
    name = "sam";
    ssh = {
      identityFile = "~/.ssh/nevarro_id_ed25519";
      nixIdentityFile = "~/.ssh/nix_nevarro_id_ed25519";
    };
    authorizedKeys = {
      sam = [
        "atlasuponraiden/nevarro"
        "kamino/nevarro"
        "zaphodbeeblebrox/nevarro"
      ];
      nixRemote = [
        "atlasuponraiden/nevarro_nix"
        "kamino/nevarro_nix"
        "zaphodbeeblebrox/nevarro_nix"
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
