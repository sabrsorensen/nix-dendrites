{
  inputs,
  lib,
  ...
}:
let
  atlasConfig = import ./config.nix;
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib; };
  hostModules = inputs.self.modules;
in
descriptorHelpers.mkServerDescriptor {
  name = "AtlasUponRaiden";
  outputName = "atlasuponraiden";
  hostModule = hostModules.nixos.atlasUponRaiden;
  identityFile = "~/.ssh/atlasuponraiden_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_atlasuponraiden_id_ed25519";
  homeProfileNames = [ "sam-home-media" ];
  localDnsRecords = [
    { hostname = "atlas"; }
  ];
  config = lib.recursiveUpdate atlasConfig.host {
    features.containers = true;
  };
  enableSystemdBoot = true;
  enableDisko = true;
  authorizedKeys.nixRemote = [
    "kamino/atlas_nix"
    "zaphodbeeblebrox/atlas_nix"
  ];
  bootstrap = {
    configurationName = "AtlasUponRaidenBootstrap";
    outputName = "atlasuponraiden-bootstrap";
    finalConfigName = "AtlasUponRaiden";
    authorizedKeyPaths = [
      "kamino/atlas"
      "no-phone/atlas"
      "zaphodbeeblebrox/atlas"
    ];
    nixos.imports = [
      (import ./bootstrap.nix { inherit inputs lib; })
    ];
    user.extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  builder = inputs.self.lib.mkInventoryBuilder {
    hostName = "AtlasUponRaiden";
    sshKey = "/root/.ssh/nix_atlasuponraiden_id_ed25519";
    systems = inputs.self.lib.shared.site.atlas.supportedSystems;
    maxJobs = inputs.self.lib.shared.site.atlas.maxJobs;
    speedFactor = inputs.self.lib.shared.site.atlas.speedFactor;
    supportedFeatures = inputs.self.lib.shared.site.atlas.systemFeatures;
  };
}
