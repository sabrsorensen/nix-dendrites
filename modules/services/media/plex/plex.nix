{
  flake.modules.nixos.plex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
      localDomain = config.systemConstants.domain;
      groupName = "media";
      mediaCfg = config.my.media;
      plexIdentity = lib.attrByPath [ "plex" ] {
        uid = 2104;
        gid = 2096;
      } mediaCfg.containerIdentities;
      tautulliIdentity = lib.attrByPath [ "tautulli" ] {
        uid = 2106;
        gid = 2096;
      } mediaCfg.containerIdentities;
    in
    {
      users.users = {
        plex = {
          isSystemUser = true;
          group = groupName;
          uid = toInt plexIdentity.uid;
        };
        kitana = {
          isSystemUser = true;
          group = groupName;
        };
        tautulli = {
          isSystemUser = true;
          group = groupName;
          uid = toInt tautulliIdentity.uid;
        };
      };
      my.localDns.records = [
        { hostname = "plex"; }
      ];
      my.media.caddy.apexRoutes = [
        ''
          redir /tautulli /tautulli/
          route /tautulli/* {
            filter {
              content_type text/html.*
              search_pattern </head>
              replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/tautulli/aquamarine.css'></head>"
            }
            reverse_proxy /tautulli/* 127.0.0.1:8181 {
              header_up -Accept-Encoding
            }
          }
          redir /kitana /kitana/
          reverse_proxy /kitana/* 127.0.0.1:31337
        ''
      ];
      my.media.caddy.virtualHosts."plex.{$DOMAIN}" = [
        ''
          filter {
            content_type text/html.*
            search_pattern </head>
            replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/plex/aquamarine.css'></head>"
          }
          reverse_proxy /* 127.0.0.1:32400 {
            header_up -Accept-Encoding
          }
        ''
      ];
      virtualisation.oci-containers.containers."plex" = {
        image = "lscr.io/linuxserver/plex:1.43.2.10687-563d026ea-ls307";
        autoStart = true;
        environment = {
          "ADVERTISE_IP" = "https://plex.${localDomain}/";
          "PUID" = lib.toString config.users.users.plex.uid;
          "PGID" = lib.toString config.users.groups.${groupName}.gid;
          "PLEX_UID" = lib.toString config.users.users.plex.uid;
          "PLEX_GID" = lib.toString config.users.groups.${groupName}.gid;
          "PLEX_CLAIM" = "";
          "TZ" = config.time.timeZone;
          "VERSION" = "docker";
        };
        volumes = [
          "${mediaCfg.dataRoot}:/data:rw"
          "/dev/shm/:/transcode:rw"
          "/etc/localtime:/etc/localtime:ro"
          "${mediaCfg.configRoot}/plex:/config:rw"
        ];
        ports = [
          "1900:1900/udp"
          "3005:3005/tcp"
          "8324:8324/tcp"
          "32400:32400/tcp"
          "32410:32410/udp"
          "32412:32412/udp"
          "32413:32413/udp"
          "32414:32414/udp"
          "32469:32469/tcp"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "false";
        };
        log-driver = "journald";
        extraOptions = [
          "--device=/dev/dri:/dev/dri:rwm"
          "--hostname=plex"
          "--network-alias=plex"
        ];
      };
      virtualisation.oci-containers.containers."tautulli" = {
        image = "ghcr.io/sabrsorensen/tautulli-deluge";
        login = {
          registry = "ghcr.io";
          username = "sabrsorensen";
          passwordFile = config.sops.secrets.ghcr_token.path;
        };
        autoStart = true;
        environment = {
          "PUID" = lib.toString config.users.users.tautulli.uid;
          "PGID" = lib.toString config.users.groups.${groupName}.gid;
          "TZ" = config.time.timeZone;
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${mediaCfg.configRoot}/plex/Library/Application Support/Plex Media Server/Logs/:/plex_logs:rw"
          "${mediaCfg.configRoot}/tautulli:/config:rw"
        ];
        ports = [
          "127.0.0.1:8181:8181/tcp"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        extraOptions = [
          "--network-alias=tautulli"
        ];
      };
      virtualisation.oci-containers.containers."kitana" = {
        image = "pannal/kitana";
        autoStart = true;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${mediaCfg.configRoot}/kitana:/app/data:rw"
        ];
        ports = [
          "127.0.0.1:31337:31337/tcp"
        ];
        cmd = [
          "-B"
          "0.0.0.0:31337"
          "-p"
          "/kitana"
          "-P"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        extraOptions = [
          "--network-alias=kitana"
        ];
      };
    };
}
