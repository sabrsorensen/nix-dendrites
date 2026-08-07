{ inputs, ... }:
let
  homeModule =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.ssh;
    in
    {
      options = {
        my.features.ssh = lib.mkEnableOption "SSH client configuration";
        my.ssh = {
          domain = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "DNS domain used for generated SSH host entries.";
          };
          hostName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Current host name, omitted from generated SSH peers.";
          };
          canDeployRemotely = lib.mkEnableOption "remote deployment SSH helpers";
          includeHostBlocks = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to generate managed SSH host blocks.";
          };
        };
      };

      config = lib.mkIf config.my.features.ssh {
        assertions = [
          {
            assertion = cfg.domain != "" && cfg.hostName != "";
            message = "SSH configuration requires my.ssh.domain and hostName.";
          }
        ];
        programs.ssh =
          (import ./_ssh.nix {
            inherit lib;
            canDeployRemotely = cfg.canDeployRemotely;
            domain = cfg.domain;
            host = {
              name = cfg.hostName;
            };
            inherit (cfg) includeHostBlocks;
          }).programs.ssh;
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.ssh = homeModule;
}
