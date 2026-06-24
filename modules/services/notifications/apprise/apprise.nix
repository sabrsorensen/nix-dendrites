{
  flake.modules.nixos.apprise =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.apprise;
      containerUid = 2200;
      containerGid = 2200;
      localAddr = "127.0.0.1:8000";
      serviceName = "apprise";
    in
    {
      options.my.services.apprise = {
        enable = lib.mkEnableOption "Apprise notification service";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };

        dataDir = lib.mkOption {
          type = lib.types.str;
          default = "/opt/apprise/config";
        };

        attachDir = lib.mkOption {
          type = lib.types.str;
          default = "/opt/apprise/attach";
        };
      };

      config = lib.mkIf cfg.enable {
        users.groups.${serviceName}.gid = containerGid;
        users.users.${serviceName} = {
          isSystemUser = true;
          group = serviceName;
          uid = containerUid;
        };

        my.localDns.records = [
          { hostname = cfg.hostName; }
        ];

        my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
          ''
            basic_auth /* {
                sorenssa {$APPRISE_PASSWORD}
            }
            reverse_proxy /* ${localAddr}
          ''
        ];

        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 ${serviceName} ${serviceName} -"
          "d ${cfg.attachDir} 0750 ${serviceName} ${serviceName} -"
        ];

        virtualisation.oci-containers.containers.${serviceName} = {
          image = "ghcr.io/caronc/apprise:1.5.0";
          autoStart = true;
          environment = {
            APPRISE_ADMIN = "y";
            APPRISE_STATEFUL_MODE = "simple";
            APPRISE_WORKER_COUNT = "1";
            PUID = lib.toString config.users.users.${serviceName}.uid;
            PGID = lib.toString config.users.groups.${serviceName}.gid;
            TZ = config.time.timeZone;
          };
          volumes = [
            "${cfg.dataDir}:/config:rw"
            "${cfg.attachDir}:/attach:rw"
          ];
          ports = [
            "${localAddr}:8000/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            "--health-cmd=curl -fsS http://127.0.0.1:8000/status >/dev/null || exit 1"
            "--health-interval=30s"
            "--health-timeout=5s"
            "--health-retries=3"
            "--health-start-period=20s"
          ];
        };
      };
    };
}
