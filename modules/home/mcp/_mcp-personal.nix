{ pkgs, ... }:
{
  # The personal Arr MCP is launched through npx.
  home.packages = [ pkgs.nodejs ];

  programs.mcp = {
    enable = true;
    servers.Arr = {
      command = "npx";
      args = [
        "-y"
        "mcp-arr-server"
      ];
      env = { };
    };
  };
}
