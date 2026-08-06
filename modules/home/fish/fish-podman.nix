{ ... }:
let
  homeModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.fish.podman.enable = lib.mkEnableOption "Fish Podman helpers";
      config = lib.mkIf (config.my.features.fish && config.my.fish.podman.enable) {
        programs.fish.functions = import ./_functions/_podman-content.nix { };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish-podman = homeModule;
}
