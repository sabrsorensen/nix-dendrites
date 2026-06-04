{
  inputs,
  lib,
  systemName,
  homeModule,
  extraImports ? [ ],
  extraHostConfig ? { },
  primaryInteractiveUser,
  sshIdentityFile,
  nixIdentityFile,
}:
{
  flake.modules.nixos.${systemName} =
    { ... }:
    {
      imports = extraImports ++ [
        inputs.self.modules.nixos.deploy-defaults
        extraHostConfig
      ];

      my.host = {
        inherit primaryInteractiveUser;
        roles = {
          workstation = true;
          desktop = true;
        };
        deploy = {
          canDeployRemotely = true;
          enableRemoteUser = true;
          sleepy = true;
        };
        ssh.enableNixBlocks = true;
        syncthing = {
          mode = "home";
          hasTray = true;
        };
      };
    };

  flake.modules.homeManager.${systemName} = homeModule;

  flake.lib.hostInventory.${systemName} = inputs.self.lib.mkInventoryHost {
    ssh = inputs.self.lib.mkInventorySsh {
      base = inputs.self.lib.mkInventorySshBase {
        user = primaryInteractiveUser;
        identityFile = sshIdentityFile;
      };
      nix = inputs.self.lib.mkInventorySshNix {
        identityFile = nixIdentityFile;
      };
    };
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "switch";
    };
    outputs = inputs.self.lib.mkNixosOutputs {
      system = "x86_64-linux";
      name = lib.strings.toLower systemName;
      configuration = systemName;
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" systemName;
}
