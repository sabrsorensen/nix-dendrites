{
  lib,
  steamdeck,
}:
{
  mkRegisteredHost =
    descriptor:
    let
      host = descriptor.platform.host;
      registration = descriptor.platform.registration steamdeck descriptor;
    in
    {
      flake.modules.nixos = lib.listToAttrs (
        map (variant: {
          name = variant.name;
          value = registration.mkVariantModule variant;
        }) host.nixosVariants
      );
      flake.modules.homeManager.${descriptor.home.moduleName} = registration.homeModule;
      flake.lib.hostInventory.${descriptor.hostName} = registration.mkInventory;
      flake.homeConfigurations = registration.mkHomeConfiguration;
      flake.nixosConfigurations = registration.mkNixosConfigurations;
    };
}
