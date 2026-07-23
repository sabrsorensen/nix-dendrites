{ ... }:
{
  flake.modules.nixos.apprise =
    { config, lib, ... }:
    let
      cfg = config.my.apprise;
      name = cfg.hostName;
      uid = 2200;
      gid = 2200;
      listen = "127.0.0.1:8000";
    in
    {
      options.my.apprise = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "apprise";
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
      config = lib.mkIf config.my.host.services.apprise {
        users.groups.${name}.gid = gid;
        users.users.${name} = {
          isSystemUser = true;
          group = name;
          inherit uid;
        };
        my.localDns.records = [ { hostname = name; } ];
        my.caddy.virtualHosts."${name}.{$DOMAIN}".routes = [
          ''
            basic_auth /* {
              sorenssa {$APPRISE_PASSWORD}
            }
            reverse_proxy /* ${listen}
          ''
        ];
        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 ${name} ${name} -"
          "d ${cfg.attachDir} 0750 ${name} ${name} -"
        ];
        virtualisation.oci-containers.containers.${name} = {
          image = "ghcr.io/caronc/apprise:1.5.0";
          autoStart = true;
          environment = {
            APPRISE_ADMIN = "y";
            APPRISE_STATEFUL_MODE = "simple";
            APPRISE_WORKER_COUNT = "1";
            PUID = lib.toString uid;
            PGID = lib.toString gid;
            TZ = config.time.timeZone;
          };
          volumes = [
            "${cfg.dataDir}:/config:rw"
            "${cfg.attachDir}:/attach:rw"
          ];
          ports = [ "${listen}:8000/tcp" ];
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
