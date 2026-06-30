{
  config,
  lib,
  ...
}:
let
  mediaCfg = config.my.media;
in
{
  options.my.media = {
    enable = lib.mkEnableOption "media service stack";

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
  };

  config = lib.mkIf mediaCfg.enable {
    assertions =
      let
        identities = builtins.attrValues mediaCfg.containerIdentities;
        uids = map (identity: identity.uid) identities;
      in
      [
        {
          assertion = lib.length uids == lib.length (lib.unique uids);
          message = "my.media.containerIdentities must assign a unique UID to each service.";
        }
      ];
  };
}
