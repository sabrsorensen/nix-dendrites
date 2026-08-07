{ inputs, ... }:
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
        my.features.gpg = lib.mkEnableOption "GPG configuration";
        my.gpg = {
          isGui = lib.mkEnableOption "KDE GPG tools";
          isWsl = lib.mkEnableOption "WSL-specific GPG behavior";
          secretRoot = lib.mkOption {
            type = lib.types.path;
            default = inputs.nix-secrets;
            description = "Directory containing managed GPG key material.";
          };
        };
      };
      config = lib.mkIf config.my.features.gpg (
        import ./_gpg.nix {
          inherit inputs lib pkgs;
          inherit (config.my.gpg) isGui isWsl secretRoot;
        }
      );
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.gpg = homeModule;
}
