{ ... }:
let
  homeModule = import ./_bitwarden-home.nix;
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.bitwarden = lib.mkEnableOption "Bitwarden";
      config = lib.mkIf config.my.features.bitwarden (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.bitwarden = featureModule;

  # Host-level switch only; the managed-user boundary (home/_home.nix) maps it
  # onto my.features.bitwarden.
  flake.modules.nixos.bitwarden =
    { lib, ... }:
    {
      options.my.host.features.bitwarden = lib.mkEnableOption "Bitwarden";
    };
}
