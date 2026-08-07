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
      cfg = config.my.fish.localFlake;
    in
    {
      options = {
        my.fish.localFlake = {
          enable = lib.mkEnableOption "Fish helpers for a local flake checkout";
          path = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to the local flake checkout used by Fish deployment helpers.";
          };
          configurationName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "NixOS configuration name used by local Fish deployment helpers.";
          };
          inhibitSleep = lib.mkEnableOption "sleep inhibition during local Fish deployments";
        };
      };

      config = lib.mkIf (config.my.features.fish && cfg.enable) {
        assertions = [
          {
            assertion = cfg.path != null && cfg.configurationName != "";
            message = "Local Fish flake helpers require my.fish.localFlake.path and configurationName.";
          }
        ];
        programs.fish.functions = import ./_functions/_local-checkout.nix {
          configurationName = cfg.configurationName;
          deployment.localFlakePath = cfg.path;
          inhibitSleep = cfg.inhibitSleep;
          systemdInhibit = lib.getExe' pkgs.systemd "systemd-inhibit";
        };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish-local-flake = homeModule;
}
