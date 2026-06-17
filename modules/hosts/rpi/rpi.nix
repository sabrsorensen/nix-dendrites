{
  inputs,
  lib,
  ...
}:
let
  rpi = import ./_public.nix { inherit inputs lib; };
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  descriptorHelpers = import ./_descriptor-helpers.nix { inherit inputs lib network; };
  descriptors = [
    (descriptorHelpers.mkStaticDescriptor {
      name = "Coruscant";
      outputName = "coruscant";
      hostName = "Coruscant";
      address = network.coruscant;
      configuration = "Coruscant";
      localDnsRecords = [
        { hostname = "homeassistant"; }
      ];
    })
    (descriptorHelpers.mkStaticDescriptor {
      name = "Ferrix";
      outputName = "ferrix";
      hostName = "Ferrix";
      address = network.ferrix;
      configuration = "Ferrix";
    })
    (descriptorHelpers.mkServiceDescriptor {
      name = "Naboo";
      outputName = "naboo";
      imageName = "NabooImage";
      imageOutputName = "naboo-image";
      configuration = "Naboo";
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
    })
    (descriptorHelpers.mkServiceDescriptor {
      name = "Nevarro";
      outputName = "nevarro";
      imageName = "NevarroImage";
      imageOutputName = "nevarro-image";
      configuration = "Nevarro";
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
    })
    (descriptorHelpers.mkDhcpDescriptor {
      name = "NixPi";
      outputName = "nixpi";
      imageName = "NixPiImage";
      imageOutputName = "nixpi-image";
      hostName = "nixpi";
      configuration = "NixPi";
    })
  ];
in
{
  imports = [ ./exports.nix ] ++ map rpi.mkRegisteredHost descriptors;
}
