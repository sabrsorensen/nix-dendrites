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
      options.my.features.wslWorkHome = lib.mkEnableOption "WSL work Home Manager profile";
      config = lib.mkIf config.my.features.wslWorkHome (import ./_wsl-work-home.nix args);
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.wsl-work-home = homeModule;
}
