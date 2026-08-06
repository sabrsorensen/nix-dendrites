{ ... }:
let
  homeModule = import ./_content.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features."github-cli" = lib.mkEnableOption "GitHub CLI";
      config = lib.mkIf config.my.features."github-cli" homeModule;
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.github-cli = featureModule;
}
