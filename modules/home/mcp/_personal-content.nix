{
  programs.mcp = {
    enable = true;
    servers = {
      Arr = {
        command = "npx";
        args = [
          "-y"
          "mcp-arr-server"
        ];
        env = { };
      };
      Context7 = {
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
      };
      GitHub = {
        url = "https://api.githubcopilot.com/mcp";
        headers.Authorization = "Bearer \${env:GITHUB_NIXOS_MCP_TOKEN}";
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
}
