{
  inputs,
  lib,
  name,
  homeModule,
  nixosImports ? [ ],
  config ? { },
  primaryUser,
  sshIdentityFile,
  nixIdentityFile,
}:
{
  flake.modules.nixos.${name} =
    { ... }:
    {
      imports = nixosImports ++ [
        inputs.self.modules.nixos.deploy-defaults
        config
      ];

      my.host = {
        primaryInteractiveUser = primaryUser;
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

  flake.modules.homeManager.${name} = homeModule;

  flake.lib.hostInventory.${name} = inputs.self.lib.mkInventoryHost {
    ssh = inputs.self.lib.mkInventorySsh {
      base = inputs.self.lib.mkInventorySshBase {
        user = primaryUser;
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
      name = lib.strings.toLower name;
      configuration = name;
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" name;
}
