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
  name = "Nevarro";
  outputName = "nevarro";
  imageName = "NevarroImage";
  imageOutputName = "nevarro-image";
  configuration = "Nevarro";
  nixosProfileNames = [ "sam-system-cli" ];
  address = network.nevarro;
  nameservers = [
    network.naboo
    "1.1.1.1"
    "9.9.9.9"
  ];
  localDomainApexIp = network.atlasuponraiden;
  identityFile = "~/.ssh/nevarro_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_nevarro_id_ed25519";
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
  securePeer = {
    name = "Naboo";
    ip = network.naboo;
  };
  serviceRoles = [
    "blocky-dns"
    "dhcp-primary"
  ];
}
