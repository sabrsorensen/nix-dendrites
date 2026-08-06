{ inputs, ... }:
let
  homeModule =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.gdrive;
    in
    {
      options = {
        my.features.gdrive = lib.mkEnableOption "Google Drive integration";
        my.gdrive = {
          secretFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "SOPS file containing the Google Drive token.";
          };
          tokenName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "SOPS key containing the Google Drive token.";
          };
        };
      };
      config = lib.mkIf config.my.features.gdrive (
        lib.mkMerge [
          (import ./_content.nix {
            inherit config lib;
            inherit (cfg) secretFile tokenName;
          })
          {
            assertions = [
              {
                assertion = cfg.secretFile != null && cfg.tokenName != "";
                message = "Google Drive requires my.gdrive.secretFile and tokenName.";
              }
            ];
          }
        ]
      );
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.gdrive = homeModule;
}
