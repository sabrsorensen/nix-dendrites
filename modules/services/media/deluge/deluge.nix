{
  flake.modules.nixos.deluge =
  {
    config,
    lib,
    ...
  }:
  let
    groupName = "media";
    localAddr = "127.0.0.1:8112";
    serviceName = "deluge";
  in
  {
    users.users.${serviceName} = {
      isSystemUser = true;
      group = groupName;
    };
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /${serviceName} /${serviceName}/
            route /${serviceName}/* {
              uri strip_prefix /${serviceName}
              filter {
                content_type text/html.*
                search_pattern </head>
                replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/${serviceName}/aquamarine.css'></head>"
              }
              reverse_proxy ${localAddr} {
                header_up X-Deluge-Base "/${serviceName}"
                header_down X-Frame-Options SAMEORIGIN
              }
            }
          '';
        };
      };
    };
    virtualisation.oci-containers.containers = {
      deluge = {
        autoStart = true;
        capabilities = {
        };
        dependsOn = [
          "gluetun"
        ];
        devices = [
        ];
        environment = {
          "DELUGE_LOGLEVEL" = "error";
          "PUID" = "${lib.toString config.users.users.${serviceName}.uid}";
          "PGID" = "${lib.toString config.users.groups.${groupName}.gid}";
          "TZ" = "America/Boise";
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
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        networks = [
        ];
        ports = [
        ];
        pull = "newer";
        volumes = [
          "/opt/${serviceName}:/config"
          "/AnomalyRealm/media/downloads:/data"
          "/AnomalyRealm/media/autoadd:/autoadd"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
      gluetun = {
        autoStart = true;
        capabilities = {
          "NET_ADMIN" = true;
          "NET_RAW" = true;
        };
        devices = [
          "/dev/net/tun:/dev/net/tun"
        ];
        environment = {
          "VPN_SERVICE_PROVIDER" = "custom";
          "VPN_TYPE" = "wireguard";
        };
        extraOptions = [
          "--network-alias=gluetun"
        ];
        image = "ghcr.io/qdm12/gluetun:latest";
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        networks = [
          "media"
        ];
        ports = [
          "${localAddr}:8112/tcp"
        ];
        pull = "newer";
        volumes = [
          "/opt/gluetun:/gluetun:rw"
          "/opt/gluetun/tmp:/tmp/gluetun:rw"
        ];
      };
    };
    # Add drop-in for deluge and gluetun containers to require the network
    systemd.services."podman-deluge".after = [ "podman-network-media.service" ];
    systemd.services."podman-deluge".requires = [ "podman-network-media.service" ];
    systemd.services."podman-gluetun".after = [ "podman-network-media.service" ];
    systemd.services."podman-gluetun".requires = [ "podman-network-media.service" ];
  };
}