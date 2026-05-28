{
  flake.modules.nixos.plex =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    readBuildValue =
      path:
      builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
    localDomain = readBuildValue "domain.txt";
    groupName = "media";
  in
  {
    users.users = {
      plex = {
        isSystemUser = true;
        group = groupName;
      };
      kitana = {
        isSystemUser = true;
        group = groupName;
      };
      tautulli = {
        isSystemUser = true;
        group = groupName;
      };
    };
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
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
          '';
        };
        virtualHosts."plex.{$DOMAIN}" = {
          extraConfig = ''
            filter {
              content_type text/html.*
              search_pattern </head>
              replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/plex/aquamarine.css'></head>"
            }
            reverse_proxy /* 127.0.0.1:32400 {
              header_up -Accept-Encoding
            }
          '';
        };
      };
    };
    virtualisation.oci-containers.containers."plex" = {
      image = "lscr.io/linuxserver/plex:latest";
      autoStart = true;
      environment = {
        "ADVERTISE_IP" = "https://plex.${localDomain}/";
        "PUID" = "978";
        "PGID" = "978";
        "PLEX_UID" = "978";
        "PLEX_GID" = "978";
        "PLEX_CLAIM" = "";
        "TZ" = "America/Boise";
        "VERSION" = "latest";
      };
      volumes = [
        "/AnomalyRealm/media:/data:rw"
        "/dev/shm/:/transcode:rw"
        "/etc/localtime:/etc/localtime:ro"
        "/opt/plex/:/config:rw"
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
        "PUID" = "976";
        "PGID" = "978";
        "TZ" = "America/Boise";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/opt/plex/Library/Application Support/Plex Media Server/Logs/:/plex_logs:rw"
        "/opt/tautulli:/config:rw"
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
        "/opt/kitana:/app/data:rw"
      ];
      ports = [
        "127.0.0.1:31337:31337/tcp"
      ];
      cmd = [ "-B" "0.0.0.0:31337" "-p" "/kitana" "-P" ];
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