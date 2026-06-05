{
  flake.modules.nixos.apprise =
    {
      config,
      lib,
      ...
    }:
    let
      containerUid = 2200;
      containerGid = 2200;
      localAddr = "127.0.0.1:8000";
      serviceName = "apprise";
      dataDir = "/opt/apprise/config";
      attachDir = "/opt/apprise/attach";
    in
    {
      users.groups.${serviceName}.gid = containerGid;
      users.users.${serviceName} = {
        isSystemUser = true;
        group = serviceName;
        uid = containerUid;
      };

      my.localDns.records = [
        { hostname = serviceName; }
      ];

      my.caddy.virtualHosts."${serviceName}.{$DOMAIN}".routes = [
        ''
          basic_auth /* {
              sorenssa {$APPRISE_PASSWORD}
          }
          reverse_proxy /* ${localAddr}
        ''
      ];

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0750 ${serviceName} ${serviceName} -"
        "d ${attachDir} 0750 ${serviceName} ${serviceName} -"
      ];

      virtualisation.oci-containers.containers.${serviceName} = {
        image = "docker.io/caronc/apprise-api:1.3.3";
        autoStart = true;
        environment = {
          APPRISE_ADMIN = "y";
          APPRISE_DEFAULT_CONFIG_ID = "ankerctl";
          APPRISE_STATEFUL_MODE = "simple";
          APPRISE_WORKER_COUNT = "1";
          PUID = lib.toString config.users.users.${serviceName}.uid;
          PGID = lib.toString config.users.groups.${serviceName}.gid;
          TZ = config.time.timeZone;
        };
        volumes = [
          "${dataDir}:/config:rw"
          "${attachDir}:/attach:rw"
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
}
