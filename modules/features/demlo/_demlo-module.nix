{ inputs, ... }:
let
  homeModule = import ./_demlo.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.demlo = lib.mkEnableOption "Demlo";
      config = lib.mkIf config.my.features.demlo (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.demlo = featureModule;

  flake.modules.nixos.demlo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.demlo {
      environment.systemPackages = [
        inputs.demlo.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
