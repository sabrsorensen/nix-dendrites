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
      options.my.features.zedWindowsDeploy =
        lib.mkEnableOption "deploying the shared Zed profile to Windows from WSL";
      config = lib.mkIf config.my.features.zedWindowsDeploy (
        import ./_zed-windows-deploy.nix args
      );
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.zed-windows-deploy = homeModule;
}
