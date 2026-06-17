{ inputs, ... }:
{
  mkRegisteredHost =
    {
      descriptor,
      mkHostModule,
      mkHomeModule ? (d: { imports = d.home.imports; }),
      system ? "x86_64-linux",
    }:
    {
      flake.modules.nixos.${descriptor.name} = mkHostModule descriptor;
      flake.modules.homeManager.${descriptor.name} = mkHomeModule descriptor;
      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.nixosConfigurations = inputs.self.lib.mkNixos system descriptor.name;
    };
}
