{ ... }:
{
  flake.modules.nixos.deluge =
    { config, lib, ... }:
    let
      serviceName = "deluge";
      cfg = config.my.deluge;
      identity = lib.attrByPath [ serviceName ] {
        uid = 2102;
        gid = 2096;
      } config.my.media.containerIdentities;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
    in
    {
      options.my.deluge.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = serviceName;
        description = "Path below the apex domain used for Deluge.";
      };

      config = lib.mkIf config.my.host.services.deluge {
        users.users.${serviceName} = {
          isSystemUser = true;
          group = "media";
          uid = toInt identity.uid;
        };
        my.caddy.apexRoutes = [
          ''
            import drop_scanners ${cfg.pathSegment}
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            route /${cfg.pathSegment}/* {
              uri strip_prefix /${cfg.pathSegment}
              filter {
                content_type text/html.*
                search_pattern </head>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/deluge/aquamarine.css'></head>"
              }
              reverse_proxy 127.0.0.1:8112 {
                header_up X-Deluge-Base "/${cfg.pathSegment}"
                header_down X-Frame-Options SAMEORIGIN
              }
            }
          ''
        ];
        virtualisation.oci-containers.containers = {
          deluge = {
            autoStart = true;
            dependsOn = [ "gluetun" ];
            environment = {
              DELUGE_LOGLEVEL = "error";
              PUID = toString config.users.users.${serviceName}.uid;
              PGID = toString config.users.groups.media.gid;
              TZ = config.time.timeZone;
            };
            extraOptions = [
              "--health-cmd=curl --fail http://localhost:8112 || exit 1"
              "--health-interval=10s"
              "--health-retries=5"
              "--health-start-period=5s"
              "--health-timeout=10s"
              "--network=container:gluetun"
            ];
            image = "lscr.io/linuxserver/deluge:2.2.0-r1-ls364";
            labels."com.centurylinklabs.watchtower.enable" = "true";
            log-driver = "journald";
            volumes = [
              "${config.my.media.configRoot}/deluge:/config"
              "${config.my.media.dataRoot}/downloads:/data"
              "${config.my.media.dataRoot}/autoadd:/autoadd"
              "/etc/localtime:/etc/localtime:ro"
            ];
          };
          gluetun = {
            autoStart = true;
            capabilities = {
              NET_ADMIN = true;
              NET_RAW = true;
            };
            devices = [ "/dev/net/tun:/dev/net/tun" ];
            environment = {
              VPN_SERVICE_PROVIDER = "custom";
              VPN_TYPE = "wireguard";
            };
            extraOptions = [ "--network-alias=gluetun" ];
            image = "ghcr.io/qdm12/gluetun:v3.41.1";
            labels."com.centurylinklabs.watchtower.enable" = "true";
            log-driver = "journald";
            networks = [ config.my.media.podmanNetwork ];
            ports = [ "127.0.0.1:8112:8112/tcp" ];
            volumes = [
              "${config.my.media.configRoot}/gluetun:/gluetun:rw"
              "${config.my.media.configRoot}/gluetun/tmp:/tmp/gluetun:rw"
            ];
          };
        };
        systemd.services."podman-deluge" = {
          after = [ "podman-network-media.service" ];
          requires = [ "podman-network-media.service" ];
        };
        systemd.services."podman-gluetun" = {
          after = [ "podman-network-media.service" ];
          requires = [ "podman-network-media.service" ];
        };
      };
    };
}
