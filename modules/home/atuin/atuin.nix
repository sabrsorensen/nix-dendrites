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
        my.features.atuin = lib.mkEnableOption "Atuin shell history synchronization";
        my.atuin.domain = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Atuin synchronization domain.";
        };
      };
      config = lib.mkIf config.my.features.atuin {
        assertions = [
          {
            assertion = config.my.atuin.domain != "";
            message = "Atuin requires my.atuin.domain.";
          }
        ];
        programs.atuin = (import ./_atuin.nix { domain = config.my.atuin.domain; }).programs.atuin;
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.atuin = homeModule;
}
