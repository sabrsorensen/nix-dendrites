{ inputs, ... }:
let
  homeModule =
    {
      config,
      lib,
      ...
    }:
    {
      options = {
        my.features.git = lib.mkEnableOption "Git";
      };

      config = lib.mkIf config.my.features.git (
        import ./_git.nix {
          inherit inputs lib;
        }
      );
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.git = homeModule;
}
