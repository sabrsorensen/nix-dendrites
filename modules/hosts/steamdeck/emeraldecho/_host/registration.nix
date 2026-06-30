{
  inputs,
  lib,
}:
steamdeck: descriptor:
let
  host = descriptor.platform.host;
  mkBootstrapModule = import ../../_profiles/bootstrap-module.nix {
    inherit
      descriptor
      inputs
      lib
      host
      steamdeck
      ;
  };
  mkHomeConfiguration = import ../../_profiles/home-configuration.nix {
    inherit descriptor inputs host;
  };
  mkInstallerModule = import ../../_profiles/installer-module.nix {
    inherit
      descriptor
      inputs
      lib
      host
      steamdeck
      ;
  };
  mkSystemModule = import ../../_profiles/system-module.nix {
    inherit
      descriptor
      inputs
      lib
      host
      steamdeck
      ;
  };
  homeModule = {
    imports = [ inputs.self.modules.homeManager.steamdeck-home ];
  };
  mkNixosConfigurations = lib.mkMerge (
    map (variant: inputs.self.lib.mkNixos "x86_64-linux" variant.name) host.nixosVariants
  );
  mkVariantModule =
    variant:
    if variant.lifecycle == "system" then
      mkSystemModule variant.bootMode
    else if variant.lifecycle == "bootstrap" then
      mkBootstrapModule variant.bootMode
    else
      mkInstallerModule variant.bootMode;
  mkInventory = inputs.self.lib.mkInventoryHost {
    ssh = inputs.self.lib.mkInventorySsh {
      base = inputs.self.lib.mkInventorySshBase {
        user = host.users.steam.name;
        identityFile = descriptor.user.ssh.identityFile;
      };
      nix = inputs.self.lib.mkInventorySshNix {
        identityFile = descriptor.user.ssh.nixIdentityFile;
      };
    };
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "build-then-switch";
    };
    dnsConfigurations = map (variant: variant.name) (
      builtins.filter (variant: variant.lifecycle == "system") host.nixosVariants
    );
    outputs =
      lib.concatMap (
        variant:
        lib.optionals variant.includeInChecks (
          inputs.self.lib.mkNixosOutputs {
            system = "x86_64-linux";
            name = variant.outputName;
            configuration = variant.name;
            buildProduct = variant.buildProduct;
          }
        )
        ++ lib.optionals variant.includeInPackages (
          inputs.self.lib.mkNixosOutputs {
            collections = [ "packages" ];
            system = "x86_64-linux";
            name = variant.outputName;
            configuration = variant.name;
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
        name = descriptor.home.outputName;
        configuration = descriptor.home.configurationName;
      };
  };
in
{
  inherit
    homeModule
    mkHomeConfiguration
    mkInventory
    mkNixosConfigurations
    mkVariantModule
    ;
}
