{
  inputs,
  lib,
  ...
}:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib network; };
in
descriptorHelpers.mkServiceDescriptor {
  name = "Naboo";
  outputName = "naboo";
  imageName = "NabooImage";
  imageOutputName = "naboo-image";
  configuration = "Naboo";
  nixosProfileNames = [ "sam-system-cli" ];
  address = network.naboo;
  nameservers = [
    network.nevarro
    "1.1.1.1"
    "9.9.9.9"
  ];
  localDomainApexIp = network.atlasuponraiden;
  identityFile = "~/.ssh/naboo_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_naboo_id_ed25519";
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
  securePeer = {
    name = "Nevarro";
    ip = network.nevarro;
  };
  failoverPeer = {
    name = "Nevarro";
    ip = network.nevarro;
  };
  serviceRoles = [
    "blocky-dns"
    "dhcp-standby"
  ];
  startKeaOnBoot = false;
}
