{ ... }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options = {
        my.features.fish = lib.mkEnableOption "Fish";
        my.fish.isWsl = lib.mkEnableOption "WSL Fish behavior";
      };
      config = lib.mkIf config.my.features.fish {
        programs.fish =
          (import ./_base-content.nix {
            inherit lib pkgs;
            inherit (config.my.fish) isWsl;
          })
          // {
            functions = import ./_functions/_base-content.nix { };
          };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish = homeModule;

  flake.modules.nixos.fish =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.my.host.home.enable {
      programs.fish.enable = true;
    };
}
