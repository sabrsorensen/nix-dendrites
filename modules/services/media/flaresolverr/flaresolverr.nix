{
  flake.modules.nixos.flaresolverr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.flaresolverr;
    in
    {
      options.my.services.flaresolverr = {
        enable = lib.mkEnableOption "FlareSolverr service";

        port = lib.mkOption {
          type = lib.types.port;
          default = 8191;
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.flaresolverr;
          description = "FlareSolverr package to run.";
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      config = lib.mkIf cfg.enable {
        services = {
          flaresolverr = {
            enable = true;
            openFirewall = cfg.openFirewall;
            package = cfg.package;
            port = cfg.port;
          };
        };
      };
    };
}
