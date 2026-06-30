{ inputs, ... }:
{
  mkRegisteredHost =
    {
      descriptor,
      mkHostModule,
      mkBootstrapModule ? null,
      mkHomeModule ? (d: { imports = d.home.imports; }),
      system ? "x86_64-linux",
    }:
    let
      bootstrapEnabled =
        descriptor ? bootstrap && descriptor.bootstrap != null && mkBootstrapModule != null;
    in
    {
      flake.modules.nixos = {
        ${descriptor.name} = mkHostModule descriptor;
      }
      // (
        if bootstrapEnabled then
          {
            ${descriptor.bootstrap.configurationName} = mkBootstrapModule descriptor;
          }
        else
          { }
      );
      flake.modules.homeManager.${descriptor.name} = mkHomeModule descriptor;
      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.nixosConfigurations =
        inputs.self.lib.mkNixos system descriptor.name
        // (
          if bootstrapEnabled then
            inputs.self.lib.mkNixos system descriptor.bootstrap.configurationName
          else
            { }
        );
    };
}
