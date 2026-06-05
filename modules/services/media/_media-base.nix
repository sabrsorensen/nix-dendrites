{
  config,
  lib,
  ...
}:
let
  mediaCfg = config.my.media;
  apexRoutes =
    mediaCfg.caddy.apexRoutes
    ++ lib.optional (mediaCfg.caddy.apexBackend != null) ''
      reverse_proxy /* ${mediaCfg.caddy.apexBackend}
    '';
in
{
  options.my.media = {
    configRoot = lib.mkOption {
      type = lib.types.str;
      default = "/opt";
      description = "Base path for media service configuration directories.";
    };

    dataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/media";
      description = "Base path for shared media library data.";
    };

    dnsServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "DNS servers for media containers that need explicit resolver settings.";
    };

    podmanNetwork = lib.mkOption {
      type = lib.types.str;
      default = "media";
      description = "Podman network name used by the media stack.";
    };

    containerIdentities = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            uid = lib.mkOption {
              type = lib.types.either lib.types.int lib.types.str;
              description = "Pinned UID for both the host service account and container runtime env.";
            };

            gid = lib.mkOption {
              type = lib.types.either lib.types.int lib.types.str;
              description = "Pinned GID used by the corresponding media workload.";
            };
          };
        }
      );
      default = { };
      description = "Host-specific UID/GID assignments used as the source of truth for media workloads.";
    };

    caddy = {
      apexBackend = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Fallback backend for the apex media site.";
      };

      apexRoutes = lib.mkOption {
        type = lib.types.listOf lib.types.lines;
        default = [ ];
        description = "Route fragments appended to the apex media Caddy site before the fallback backend.";
      };

      virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.lines);
        default = { };
        description = "Additional media-owned Caddy virtual hosts keyed by hostname.";
      };
    };
  };

  config = {
    my.caddy.apexRoutes = apexRoutes;
    my.caddy.virtualHosts = lib.mapAttrs (_: routes: {
      inherit routes;
    }) mediaCfg.caddy.virtualHosts;
  };
}
