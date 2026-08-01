{
  config,
  cfg,
  domain,
  hawkbitIdentity,
  toInt,
  ...
}:
{
  users.users = {
    hawkbit = {
      isSystemUser = true;
      group = "media";
      uid = toInt hawkbitIdentity.uid;
    };
  };
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      filter {
        content_type text/html.*
        search_pattern </head>
        replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/plex/aquamarine.css'></head>"
      }
      reverse_proxy /* 127.0.0.1:8084 {
        header_up -Accept-Encoding
      }
    ''
  ];
  virtualisation.oci-containers.containers = {
    hawkbit-ui = {
      image = "ghcr.io/dogukanarat/hawkbit-ui";
      autoStart = true;
      environment = {
        HAWKBIT_URL = "http://hawkbit-mgmt:8080";
      };
      volumes = [
      ];
      ports = [
        "127.0.0.1:8084:80"
      ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [
        "--hostname=hawkbit-ui"
        "--network-alias=hawkbit-ui"
      ];
    };
    hawkbit-mgmt-server = {
      image = "hawkbit/hawkbit-mgmt-server:latest";
      autoStart = true;
      environment = {
        PROFILES = "postgresql";
        SPRING_DATASOURCE_URL = "jdbc:postgresql://postgres:5432/hawkbit";
        SPRING_DATASOURCE_USERNAME = "postgres";
        SPRING_DATASOURCE_PASSWORD = "admin";
        SPRING_RABBITMQ_HOST = "rabbitmq";
        SPRING_RABBITMQ_USERNAME = "guest";
        SPRING_RABBITMQ_PASSWORD = "guest";
      };
      volumes = [
        "artifactrepo:/app/artifactrepo"
      ];
      ports = [ "127.0.0.1:8082:8080/tcp" ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [ "--network-alias=hawkbit-mgmt" ];
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
