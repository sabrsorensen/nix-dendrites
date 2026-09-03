{ ... }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.fish.deploy;
    in
    {
      options = {
        my.fish.deploy = {
          enable = lib.mkEnableOption "Fish remote deployment helpers";
          path = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Local flake checkout used for Fish remote deployments.";
          };
          domain = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "DNS domain used to reach deployment targets.";
          };
          inhibitSleep = lib.mkEnableOption "sleep inhibition during Fish remote deployments";
        };
      };

      config = lib.mkIf (config.my.features.fish && cfg.enable) {
        assertions = [
          {
            assertion = cfg.path != null && cfg.domain != "";
            message = "Fish deployment helpers require my.fish.deploy.path and domain.";
          }
        ];
        home.packages = [
          (pkgs.writeShellApplication {
            name = "nix-deploy";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              exec ${pkgs.python3}/bin/python3 ${./scripts/nix-deploy.py} \
                --flake ${lib.escapeShellArg (toString cfg.path)} \
                --domain ${lib.escapeShellArg cfg.domain} \
                ${lib.optionalString cfg.inhibitSleep "--inhibit-sleep"} "$@"
            '';
          })
        ];
        programs.fish.functions = {
          nhsr = "nix-deploy switch $argv";
          nhsur = "nix-deploy upgrade $argv";
          nhsur_unsafe = "nix-deploy unsafe $argv";
        };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish-deploy = homeModule;
}
