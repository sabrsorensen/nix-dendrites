{ ... }:
let
  homeModule = import ./_home-content.nix;
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
  nixosModule = import ./_nixos-content.nix;
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.bitwarden = featureModule;

  flake.modules.nixos.bitwarden =
    args@{
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
    in
    lib.mkIf host.features.bitwarden (nixosModule args);
}
