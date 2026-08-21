{
  config,
  cfg,
  domain,
  plexIdentity,
  tautulliIdentity,
  toInt,
  ...
}:
{
  users.users = {
    plex = {
      isSystemUser = true;
      group = "media";
      uid = toInt plexIdentity.uid;
    };
    kitana = {
      isSystemUser = true;
      group = "media";
    };
    tautulli = {
      isSystemUser = true;
      group = "media";
      uid = toInt tautulliIdentity.uid;
    };
  };
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.apexRoutes = [
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
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
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
  virtualisation.oci-containers.containers = {
    plex = {
      image = "lscr.io/linuxserver/plex:latest";
      pull = "newer";
      autoStart = true;
      environment = {
        ADVERTISE_IP = "https://${cfg.hostName}.${domain}/";
        PUID = toString config.users.users.plex.uid;
        PGID = toString config.users.groups.media.gid;
        PLEX_UID = toString config.users.users.plex.uid;
        PLEX_GID = toString config.users.groups.media.gid;
        PLEX_CLAIM = "";
        TZ = config.time.timeZone;
        VERSION = "docker";
      };
      volumes = [
        "${config.my.media.dataRoot}:/data:rw"
        "/dev/shm/:/transcode:rw"
        "/etc/localtime:/etc/localtime:ro"
        "${config.my.media.configRoot}/plex:/config:rw"
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
      labels."com.centurylinklabs.watchtower.enable" = "false";
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--hostname=plex"
        "--network-alias=plex"
      ];
    };
    tautulli = {
      image = "ghcr.io/sabrsorensen/tautulli-deluge";
      login = {
        registry = "ghcr.io";
        username = "sabrsorensen";
        passwordFile = config.sops.secrets.ghcr_token.path;
      };
      autoStart = true;
      environment = {
        PUID = toString config.users.users.tautulli.uid;
        PGID = toString config.users.groups.media.gid;
        TZ = config.time.timeZone;
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${config.my.media.configRoot}/plex/Library/Application Support/Plex Media Server/Logs/:/plex_logs:rw"
        "${config.my.media.configRoot}/tautulli:/config:rw"
      ];
      ports = [ "127.0.0.1:8181:8181/tcp" ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [ "--network-alias=tautulli" ];
    };
    kitana = {
      image = "pannal/kitana";
      autoStart = true;
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${config.my.media.configRoot}/kitana:/app/data:rw"
      ];
      ports = [ "127.0.0.1:31337:31337/tcp" ];
      cmd = [
        "-B"
        "0.0.0.0:31337"
        "-p"
        "/kitana"
        "-P"
      ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [ "--network-alias=kitana" ];
    };
  };
}
