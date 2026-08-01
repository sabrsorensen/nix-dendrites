{
  config,
  cfg,
  domain,
  hawkbitIdentity,
  lib,
  toInt,
  ...
}:
let
  lanAddress = config.my.host.address;
  mediaNetwork = config.my.media.podmanNetwork;
  hawkbitDataRoot = "${config.my.media.configRoot}/hawkbit";
  databaseEnvironment = {
    PROFILES = "postgresql";
    SPRING_DATASOURCE_URL = "jdbc:postgresql://postgres:5432/hawkbit";
    SPRING_DATASOURCE_USERNAME = "postgres";
    SPRING_DATASOURCE_PASSWORD = "admin";
    SPRING_RABBITMQ_HOST = "rabbitmq";
    SPRING_RABBITMQ_USERNAME = "guest";
    SPRING_RABBITMQ_PASSWORD = "guest";
  };
in
{
  assertions = [
    {
      assertion = lanAddress != null;
      message = "hawkBit requires my.host.address so its LAN endpoints have a specific bind address.";
    }
  ];
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
      basic_auth /* {
          sorenssa {$HAWKBIT_PASSWORD}
      }
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
      networks = [ mediaNetwork ];
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
    hawkbit-ddi = {
      image = "hawkbit/hawkbit-ddi-server:latest";
      autoStart = true;
      dependsOn = [
        "postgres"
        "rabbitmq"
      ];
      environment = databaseEnvironment;
      networks = [ mediaNetwork ];
      ports = [ "${lanAddress}:8081:8081/tcp" ];
      volumes = [ "${hawkbitDataRoot}/artifactrepo:/app/artifactrepo:rw" ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [ "--network-alias=hawkbit-ddi" ];
    };
    hawkbit-dmf = {
      image = "hawkbit/hawkbit-dmf-server:latest";
      autoStart = true;
      dependsOn = [
        "postgres"
        "rabbitmq"
      ];
      environment = databaseEnvironment;
      networks = [ mediaNetwork ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [ "--network-alias=hawkbit-dmf" ];
    };
    hawkbit-mgmt-server = {
      image = "hawkbit/hawkbit-mgmt-server:latest";
      autoStart = true;
      dependsOn = [
        "postgres"
        "rabbitmq"
      ];
      environment = databaseEnvironment;
      networks = [ mediaNetwork ];
      volumes = [ "${hawkbitDataRoot}/artifactrepo:/app/artifactrepo:rw" ];
      ports = [ "${lanAddress}:8082:8080/tcp" ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [ "--network-alias=hawkbit-mgmt" ];
    };
    postgres = {
      image = "postgres:16.5";
      autoStart = true;
      environment = {
        POSTGRES_DB = "hawkbit";
        POSTGRES_USER = "postgres";
        POSTGRES_PASSWORD = "admin";
      };
      networks = [ mediaNetwork ];
      ports = [ "${lanAddress}:5432:5432/tcp" ];
      volumes = [ "${hawkbitDataRoot}/postgres:/var/lib/postgresql/data:rw" ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [
        "--hostname=postgres"
        "--network-alias=postgres"
        "--health-cmd=pg_isready -d hawkbit -U postgres"
        "--health-interval=20s"
        "--health-retries=10"
      ];
    };
    rabbitmq = {
      image = "rabbitmq:4-management-alpine";
      autoStart = true;
      environment = {
        RABBITMQ_DEFAULT_VHOST = "/";
        RABBITMQ_DEFAULT_USER = "guest";
        RABBITMQ_DEFAULT_PASS = "guest";
      };
      networks = [ mediaNetwork ];
      ports = [
        "${lanAddress}:15672:15672/tcp"
        "${lanAddress}:5672:5672/tcp"
      ];
      labels."com.centurylinklabs.watchtower.enable" = "true";
      log-driver = "journald";
      extraOptions = [
        "--hostname=rabbitmq"
        "--network-alias=rabbitmq"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [
    5432
    5672
    8081
    8082
    15672
  ];
  systemd.services =
    lib.genAttrs
      [
        "podman-hawkbit-ui"
        "podman-hawkbit-ddi"
        "podman-hawkbit-dmf"
        "podman-hawkbit-mgmt-server"
        "podman-postgres"
        "podman-rabbitmq"
      ]
      (_: {
        after = [ "podman-network-media.service" ];
        requires = [ "podman-network-media.service" ];
      });
}
