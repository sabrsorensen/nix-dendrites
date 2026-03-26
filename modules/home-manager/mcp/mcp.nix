{
  flake.modules.homeManager.mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
    in
    {
      programs.mcp = {
        enable = true;
        servers = {
          Context7 = lib.mkDefault {
            url = "https://mcp.context7.com/mcp";
            headers = {
              CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
            };
          };
          GitHub = lib.mkDefault {
            url = "https://api.githubcopilot.com/mcp";
            headers = {
              Authorization = "Bearer \${env:GITHUB_NIXOS_MCP_TOKEN}";
            };
          };
          NixOS = {
            command = "nix";
            args = [
              "run"
              "github:utensils/mcp-nixos"
              "--"
            ];
            startup_timeout_sec = 300;
          };
        };
      };
    };
}
