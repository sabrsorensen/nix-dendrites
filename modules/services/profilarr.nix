{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.profilarr =
    { config, lib, ... }:
    let
      serviceName = "profilarr";
      cfg = config.my.profilarr;
      identity = lib.attrByPath [ serviceName ] {
        uid = 2105;
        gid = 2096;
      } config.my.media.containerIdentities;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
    in
    {
      options.my.profilarr = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
          description = "Local hostname published for Profilarr.";
        };
        origin = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional public URL override for Profilarr.";
        };
      };

      config = lib.mkIf config.my.host.services.profilarr {
        users.users.${serviceName} = {
          isSystemUser = true;
          group = "media";
          uid = toInt identity.uid;
        };
        systemd.tmpfiles.rules = [
          "d ${config.my.media.configRoot}/${serviceName} 0750 ${serviceName} media -"
        ];
        my.localDns.records = [ { hostname = cfg.hostName; } ];
        my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [ "reverse_proxy /* 127.0.0.1:6868" ];
        virtualisation.oci-containers.containers.${serviceName} = {
          image = "ghcr.io/dictionarry-hub/profilarr:2.0.8";
          autoStart = true;
          environment = {
            PUID = toString config.users.users.${serviceName}.uid;
            PGID = toString config.users.groups.media.gid;
            TZ = config.time.timeZone;
            ORIGIN = if cfg.origin != null then cfg.origin else "https://${cfg.hostName}.${domain}/";
          };
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${config.my.media.configRoot}/${serviceName}:/config"
          ];
          ports = [ "127.0.0.1:6868:6868/tcp" ];
          labels."com.centurylinklabs.watchtower.enable" = "true";
          log-driver = "journald";
          extraOptions = [ "--network-alias=${serviceName}" ];
        };
      };
    };
}
