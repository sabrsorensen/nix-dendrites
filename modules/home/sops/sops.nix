{ inputs, ... }:
let
  homeModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options = {
        my.features.sops = lib.mkEnableOption "SOPS-managed Home Manager secrets";
        my.sops = {
          homeDirectory = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Home directory used to locate managed personal SOPS configuration.";
          };
          isManagedPersonal = lib.mkEnableOption "managed personal SOPS configuration";
        };
      };
      config = lib.mkIf config.my.features.sops (
        lib.mkMerge [
          (import ./_sops.nix {
            inherit inputs lib pkgs;
            inherit (config.my.sops) homeDirectory isManagedPersonal;
          })
          {
            assertions = [
              {
                assertion = config.my.sops.homeDirectory != null;
                message = "Home Manager SOPS requires my.sops.homeDirectory.";
              }
            ];
          }
        ]
      );
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.sops = homeModule;
}
