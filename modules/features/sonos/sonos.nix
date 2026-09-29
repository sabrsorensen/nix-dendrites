{ inputs, ... }:
let
  homeModule = import ./_sonos-home.nix { sonolin-src = inputs.sonolin; };
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.sonos = lib.mkEnableOption "Sonos controllers (Noson and Sonolin)";
      config = lib.mkIf config.my.features.sonos (homeModule args);
    };
  nixosModule = import ./_sonos-nixos.nix;
in
{
  # Built from source off upstream's default branch (no tags yet); the version
  # comes from its pyproject.toml, so a flake.lock bump is the whole update.
  flake-file.inputs.sonolin = {
    url = "github:alexsson-xexpanderx/sonolin";
    flake = false;
  };

  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.sonos = featureModule;

  flake.modules.nixos.sonos =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.sonos = lib.mkEnableOption "Sonos controllers (Noson and Sonolin)";
      config = lib.mkIf (config.my.host.features.sonos && config.my.host.home.enable) (nixosModule args);
    };
}
