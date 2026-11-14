{ ... }:
let
  homeModule = import ./_ghostty.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.ghostty = lib.mkEnableOption "Ghostty";
      config = lib.mkIf config.my.features.ghostty (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.ghostty = featureModule;

  flake.modules.nixos.ghostty =
    { lib, ... }:
    {
      options.my.host.features.ghostty = lib.mkEnableOption "the declarative Ghostty terminal profile";
    };
}
