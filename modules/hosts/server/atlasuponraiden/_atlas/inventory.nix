{ inputs, ... }:
inputs.self.lib.mkInventoryHost {
  builder = inputs.self.lib.mkInventoryBuilder {
    hostName = "AtlasUponRaiden";
    sshKey = "/root/.ssh/nix_atlasuponraiden_id_ed25519";
    systems = inputs.self.lib.shared.site.atlas.supportedSystems;
    maxJobs = inputs.self.lib.shared.site.atlas.maxJobs;
    speedFactor = inputs.self.lib.shared.site.atlas.speedFactor;
    supportedFeatures = inputs.self.lib.shared.site.atlas.systemFeatures;
  };
  ssh = inputs.self.lib.mkInventorySsh {
    base = inputs.self.lib.mkInventorySshBase {
      user = "sam";
      identityFile = "~/.ssh/atlasuponraiden_id_ed25519";
    };
    nix = inputs.self.lib.mkInventorySshNix {
      identityFile = "~/.ssh/nix_atlasuponraiden_id_ed25519";
    };
  };
  deploy = inputs.self.lib.mkInventoryDeploy {
    remoteMethod = "switch";
  };
  outputs = inputs.self.lib.mkNixosOutputs {
    system = "x86_64-linux";
    name = "atlasuponraiden";
    configuration = "AtlasUponRaiden";
  };
}
