{
  lib,
  steamdeck,
}:
{
  mkRegisteredHost =
    descriptor:
    let
      host = descriptor.platform.host;
      registration = descriptor.platform.registration steamdeck;
    in
    {
      flake.modules.nixos = lib.listToAttrs (
        map (variant: {
          name = variant.name;
          value = registration.mkVariantModule variant;
        }) host.nixosVariants
      );
      flake.modules.homeManager.${host.primaryHostName} = registration.homeModule;
      flake.lib.hostInventory.${host.primaryHostName} = registration.mkInventory descriptor;
      flake.homeConfigurations = registration.mkHomeConfiguration;
      flake.nixosConfigurations = registration.mkNixosConfigurations;
    };
}
