{
  inputs,
  lib,
  ...
}:
{
  nixosWslHomeDefaults = import ./nixos-wsl/_nixos-wsl/home-defaults.nix { inherit inputs lib; };

  mkRegisteredHost =
    descriptor:
    {
      flake.modules.nixos.${descriptor.name} = {
        imports = descriptor.nixos.imports;

        my.host = descriptor.config;
      };
      flake.modules.homeManager.${descriptor.name} = descriptor.home.module;
      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" descriptor.name;
    };
}
