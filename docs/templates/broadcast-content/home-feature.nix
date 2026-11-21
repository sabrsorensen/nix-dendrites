# modules/home/example/example.nix
{ ... }:
let
  homeModule = import ./_example.nix;
  featureModule =
    args@{ config, lib, ... }:
    {
      options.my.features.example = lib.mkEnableOption "Example";
      config = lib.mkIf config.my.features.example (homeModule args);
    };
in
{
  # Broadcast to every managed user; self-gates on my.features.example.
  dendritic.homeManagerModules = [ featureModule ];
  # Standalone Home Manager configurations import it by name.
  flake.modules.homeManager.example = featureModule;

  # Host-fact vocabulary only. The HM boundary (modules/home/home/_home.nix)
  # maps it: `my.features.example = host.features.example;`
  flake.modules.nixos.example =
    { lib, ... }:
    {
      options.my.host.features.example = lib.mkEnableOption "Example";
    };
}

# modules/home/example/_example.nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.example ];
}
