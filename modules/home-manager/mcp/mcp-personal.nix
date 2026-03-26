{
  flake.modules.homeManager."mcp-personal" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
    in
    {
      home.packages = with pkgs; ([
        nodejs_25
      ]);
      programs.mcp = {
        enable = true;
        servers = {
          Arr = {
            command = "npx";
            args = [
              "-y"
              "mcp-arr-server"
            ];
            env = {
              #"SONARR_URL" = "http://localhost:8989";
              #"SONARR_API_KEY" = "your-sonarr-api-key";
              #"RADARR_URL" = "http://localhost:7878";
              #"RADARR_API_KEY" = "your-radarr-api-key";
              #"PROWLARR_URL" = "http://localhost:9696";
              #"PROWLARR_API_KEY" = "your-prowlarr-api-key";
            };
          };
        };
      };
    };
}
