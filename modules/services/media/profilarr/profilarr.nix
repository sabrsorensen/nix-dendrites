{
  flake.modules.nixos.profilarr =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.profilarr;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
      localDomain = config.systemConstants.domain;
      groupName = "media";
      localAddr = "127.0.0.1:6868";
      mediaCfg = config.my.media;
      serviceName = "profilarr";
      containerIdentity =
        lib.attrByPath
          [
            serviceName
          ]
          {
            uid = 2105;
            gid = 2096;
          }
          mediaCfg.containerIdentities;
    in
    {
      options.my.services.profilarr = {
        enable = lib.mkEnableOption "Profilarr media service";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };

        origin = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        users.users.${serviceName} = {
          isSystemUser = true;
          group = groupName;
          uid = toInt containerIdentity.uid;
        };
        my.localDns.records = [
          { hostname = cfg.hostName; }
        ];
        my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
          ''
            reverse_proxy /* ${localAddr}
          ''
        ];
        virtualisation.oci-containers.containers.${serviceName} = {
          image = "ghcr.io/dictionarry-hub/profilarr:2.0.8";
          autoStart = true;
          environment = {
            "PUID" = lib.toString config.users.users.${serviceName}.uid;
            "PGID" = lib.toString config.users.groups.${groupName}.gid;
            "TZ" = config.time.timeZone;
            "ORIGIN" = if cfg.origin != null then cfg.origin else "https://${cfg.hostName}.${localDomain}/";
          };
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${mediaCfg.configRoot}/${serviceName}:/config"
          ];
          ports = [
            "${localAddr}:6868/tcp"
          ];
          labels = {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
          log-driver = "journald";
          extraOptions = [
            "--network-alias=${serviceName}"
          ];
        };
      };
    };
}
