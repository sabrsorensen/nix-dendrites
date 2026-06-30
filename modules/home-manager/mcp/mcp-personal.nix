{
  flake.modules.homeManager."mcp-personal" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      enableMcp = config.my.host.is.laptop || config.my.host.is.desktop;
    in
    lib.mkIf enableMcp {
      home.packages = with pkgs; ([
        nodejs
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
