{
  inputs,
  lib,
  ...
}:
let
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib; };
  hostModules = inputs.self.modules;
in
descriptorHelpers.mkServerDescriptor {
  name = "AtlasUponRaiden";
  outputName = "atlasuponraiden";
  hostModule = hostModules.nixos.atlasUponRaiden;
  identityFile = "~/.ssh/atlasuponraiden_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_atlasuponraiden_id_ed25519";
  homeImports = import ./home-imports.nix { inherit inputs; };
  localDnsRecords = import ./local-dns-records.nix;
  config = import ./config.nix;
  extraImports = with hostModules.nixos; [
    samba
    deploy-defaults
    system-cli
    systemd-boot
    disko
    podman
    cross-compile
    nix-index
    caddy
    apprise
    ankerctl
    immich
    mealie
    media-server
    minecraft-server
    demlo
    scrutiny
    syncthing-server
  ];
  builder = inputs.self.lib.mkInventoryBuilder {
    hostName = "AtlasUponRaiden";
    sshKey = "/root/.ssh/nix_atlasuponraiden_id_ed25519";
    systems = inputs.self.lib.shared.site.atlas.supportedSystems;
    maxJobs = inputs.self.lib.shared.site.atlas.maxJobs;
    speedFactor = inputs.self.lib.shared.site.atlas.speedFactor;
    supportedFeatures = inputs.self.lib.shared.site.atlas.systemFeatures;
  };
}
