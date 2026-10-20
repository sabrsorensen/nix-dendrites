{ ... }:
let
  homeModule = import ./_persistence.nix;
  featureModule =
    args@{
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    {
      options.my.features.persistence = lib.mkEnableOption "Home persistence";
      # home.persistence only exists where impermanence's Home Manager module
      # is imported (the NixOS managed-user boundary); standalone Home Manager
      # (e.g. emeraldecho-steamos) must not see the definition at all.
      config = lib.mkMerge [
        (lib.optionalAttrs (options.home ? persistence) (
          lib.mkIf config.my.features.persistence (homeModule args)
        ))
        {
          assertions = [
            {
              assertion = !config.my.features.persistence || options.home ? persistence;
              message = "my.features.persistence requires impermanence's Home Manager module (home.persistence).";
            }
          ];
        }
      ];
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.persistence = featureModule;

  flake.modules.nixos.persistence =
    { lib, ... }:
    {
      options.my.host.features.persistenceHome = lib.mkEnableOption "Home Manager persistent state";
    };
}
