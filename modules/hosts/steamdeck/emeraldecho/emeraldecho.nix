{
  inputs,
  lib,
  ...
}:
let
  host = import ./_host/default.nix { inherit inputs; };
  homeModule = import ../_profiles/home-module.nix { inherit inputs; };
  mkEmeraldSystemModule = import ../_profiles/system-module.nix {
    inherit inputs lib host;
  };
  mkEmeraldBootstrapModule = import ../_profiles/bootstrap-module.nix {
    inherit inputs lib host;
  };
  mkEmeraldInstallerModule = import ../_profiles/installer-module.nix {
    inherit inputs lib host;
  };
  lifecycleModule =
    variant:
    if variant.lifecycle == "system" then
      mkEmeraldSystemModule variant.bootMode
    else if variant.lifecycle == "bootstrap" then
      mkEmeraldBootstrapModule variant.bootMode
    else
      mkEmeraldInstallerModule variant.bootMode;
in
{
  flake.modules.nixos = lib.listToAttrs (
    map (variant: {
      name = variant.moduleName;
      value = lifecycleModule variant;
    }) host.nixosVariants
  );

  flake.modules.homeManager.${host.primaryHostName} = homeModule;

  flake.lib.hostInventory.${host.primaryHostName} = inputs.self.lib.mkInventoryHost {
    ssh = inputs.self.lib.mkInventorySsh {
      base = inputs.self.lib.mkInventorySshBase {
        user = host.users.steam.name;
        identityFile = "~/.ssh/emeraldecho_id_ed25519";
      };
      nix = inputs.self.lib.mkInventorySshNix {
        identityFile = "~/.ssh/nix_emeraldecho_id_ed25519";
      };
    };
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "build-then-switch";
    };
    dnsConfigurations = map (variant: variant.moduleName) (
      builtins.filter (variant: variant.lifecycle == "system") host.nixosVariants
    );
    outputs =
      lib.concatMap (
        variant:
        lib.optionals variant.includeInChecks (
          inputs.self.lib.mkNixosOutputs {
            system = "x86_64-linux";
            name = variant.outputName;
            configuration = variant.moduleName;
            buildProduct = variant.buildProduct;
          }
        )
        ++ lib.optionals variant.includeInPackages (
          inputs.self.lib.mkNixosOutputs {
            collections = [ "packages" ];
            system = "x86_64-linux";
            name = variant.outputName;
            configuration = variant.moduleName;
            buildProduct = variant.buildProduct;
          }
        )
      ) host.nixosVariants
      ++ inputs.self.lib.mkHomeOutputs {
        collections = [
          "checks"
          "packages"
        ];
        system = "x86_64-linux";
        name = "home-deck-emeraldecho";
        configuration = host.homeConfigurationName;
      };
  };

  flake.homeConfigurations = import ../_profiles/home-configuration.nix {
    inherit inputs host;
  };

  flake.nixosConfigurations = import ../_profiles/nixos-configurations.nix {
    inherit inputs lib host;
  };
}
