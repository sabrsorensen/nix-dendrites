{ ... }:
let
  commonModule = import ./_mcp.nix;
  personalModule = import ./_mcp-personal.nix;
  workModule = import ./_mcp-work.nix;
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
