{
  inputs,
  lib,
  ...
}:
{
  # Helper functions for creating system / home-manager configurations

  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib = {

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = lib.optionals (inputs ? disko) [
          inputs.disko.nixosModules.disko
        ]
        ++ [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkHomeManager = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules =
          lib.optionals (inputs ? determinate) [
            inputs.determinate.homeManagerModules.default
          ]
          ++ [
            inputs.self.modules.homeManager.${name}
            { nixpkgs.config.allowUnfree = true; }
          ];
      };
    };

  };
}
