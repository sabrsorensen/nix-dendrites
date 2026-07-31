{ inputs, ... }:
{
  flake.modules.nixos.caddy =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.caddy;
      renderRoutes = routes: lib.concatStringsSep "\n" (lib.filter (route: route != "") routes);
      virtualHosts = lib.mapAttrs (
        _: host:
        lib.optionalAttrs (host.routes != [ ]) { extraConfig = renderRoutes host.routes; }
        // lib.optionalAttrs (host.logFormat != null) { logFormat = host.logFormat; }
      ) (lib.filterAttrs (_: host: host.routes != [ ] || host.logFormat != null) cfg.virtualHosts);
      enabled = config.my.host.services.caddy || cfg.apexRoutes != [ ] || virtualHosts != { };
    in
    {
      options.my.caddy = {
        enableFail2ban = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether a Caddy host enables Fail2ban and Cloudflare IP bans.";
        };
        apexRoutes = lib.mkOption {
          type = lib.types.listOf lib.types.lines;
          default = [ ];
          description = "Route fragments for the apex {$DOMAIN} Caddy site.";
        };
        virtualHosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.routes = lib.mkOption {
                type = lib.types.listOf lib.types.lines;
                default = [ ];
              };
              options.logFormat = lib.mkOption {
                type = lib.types.nullOr lib.types.lines;
                default = null;
                description = "Optional Caddy logFormat block for this virtual host.";
              };
            }
          );
          default = { };
          description = "Caddy route fragments keyed by virtual host.";
        };
      };

      config = lib.mkIf enabled (
        import ./_content.nix (
          args
          // {
            inherit cfg renderRoutes virtualHosts;
            caddyEnvFile = "${inputs.nix-secrets}/env_files/caddy.env";
          }
        )
      );
    };
}
