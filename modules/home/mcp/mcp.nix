{ ... }:
let
  commonModule = import ./_content.nix;
  personalModule = import ./_personal-content.nix;
  workModule = import ./_work-content.nix;
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features = {
        mcpCommon = lib.mkEnableOption "common MCP clients";
        personalMcp = lib.mkEnableOption "personal MCP clients";
        workMcp = lib.mkEnableOption "work MCP clients";
      };
      config = lib.mkMerge [
        (lib.mkIf config.my.features.mcpCommon (commonModule {
          inherit lib;
        }))
        (lib.mkIf config.my.features.personalMcp (personalModule {
          inherit pkgs;
        }))
        (lib.mkIf config.my.features.workMcp (workModule { }))
      ];
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.mcp = homeModule;
}
