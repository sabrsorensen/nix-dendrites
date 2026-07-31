{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.monitoring =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.monitoring;
      dashboards = import ./_dashboards-content.nix { inherit pkgs; };
    in
    {
      options.my.monitoring = {
        grafanaHostName = lib.mkOption {
          type = lib.types.str;
          default = "grafana";
        };
        prometheusHostName = lib.mkOption {
          type = lib.types.str;
          default = "prometheus";
        };
        basicAuthUser = lib.mkOption {
          type = lib.types.str;
          default = "sorenssa";
        };
        basicAuthPasswordEnvVar = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional Caddy environment variable used for monitoring basic authentication.";
        };
        enableSmartctlExporter = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        nodeTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        blockyTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        smartctlTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
      config = lib.mkIf config.my.host.services.monitoring (
        import ./_content.nix (
          args
          // {
            inherit
              cfg
              domain
              ;
            inherit (dashboards)
              grafanaBlockyDashboard
              grafanaDashboard
              grafanaRpiServicesDashboard
              ;
            secretsFile = "${inputs.nix-secrets}/secrets.yaml";
          }
        )
      );
    };
}
