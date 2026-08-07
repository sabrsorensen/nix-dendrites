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
      deployment = {
        localFlakePath = cfg.path;
      };
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
        programs.fish.functions = import ./_functions/_remote-deployment.nix {
            inherit deployment;
            domain = cfg.domain;
            inhibitSleep = cfg.inhibitSleep;
            systemdInhibit = lib.getExe' pkgs.systemd "systemd-inhibit";
          };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.fish-deploy = homeModule;
}
