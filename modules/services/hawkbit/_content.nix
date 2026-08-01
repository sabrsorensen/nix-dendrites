{
  config,
  cfg,
  domain,
  hawkbitIdentity,
  hawkbitPassword,
  lib,
  pkgs,
  toInt,
  ...
}:
let
  lanAddress = config.my.host.address;
  docker = "${pkgs.docker}/bin/docker";
  dockerNetwork = "hawkbit";
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
  mgmtEnvironment = databaseEnvironment // {
    HAWKBIT_SECURITY_USER_ADMIN_TENANT = "DEFAULT";
    HAWKBIT_SECURITY_USER_ADMIN_PASSWORD = hawkbitPassword;
    HAWKBIT_SECURITY_USER_ADMIN_ROLES = "TENANT_ADMIN";
    HAWKBIT_SECURITY_USER_CUSHYCHICKEN_TENANT = "DEFAULT";
    HAWKBIT_SECURITY_USER_CUSHYCHICKEN_PASSWORD = hawkbitPassword;
    HAWKBIT_SECURITY_USER_CUSHYCHICKEN_ROLES = "TENANT_ADMIN";
    HAWKBIT_SERVER_REPOSITORY_IMPLICIT_TENANT_CREATE_ALLOWED = "true";
  };
  escapeArgs = args: lib.escapeShellArgs args;
  environmentArgs =
    environment:
    lib.concatLists (
      lib.mapAttrsToList (name: value: [
        "--env"
        "${name}=${value}"
      ]) environment
    );
  volumeArgs =
    volumes:
    lib.concatLists (
      map (volume: [
        "--volume"
        volume
      ]) volumes
    );
  portArgs =
    ports:
    lib.concatLists (
      map (port: [
        "--publish"
        port
      ]) ports
    );
  networkArgs =
    aliases:
    lib.concatLists (
      map (alias: [
        "--network-alias"
        alias
      ]) aliases
    );
  dockerRun =
    {
      name,
      image,
      environment ? { },
      volumes ? [ ],
      ports ? [ ],
      aliases ? [ ],
      hostname ? null,
      extraArgs ? [ ],
    }:
    escapeArgs (
      [
        docker
        "run"
        "--name"
        name
        "--network"
        dockerNetwork
      ]
      ++ lib.optional (hostname != null) "--hostname=${hostname}"
      ++ networkArgs aliases
      ++ environmentArgs environment
      ++ volumeArgs volumes
      ++ portArgs ports
      ++ extraArgs
      ++ [ image ]
    );
  dockerImage = image: {
    ExecStartPre = "-${docker} pull ${image}";
  };
  mkDockerService =
    {
      name,
      image,
      environment ? { },
      volumes ? [ ],
      ports ? [ ],
      aliases ? [ ],
      hostname ? null,
      extraArgs ? [ ],
      after ? [ ],
      requires ? [ ],
    }:
    {
      inherit after requires;
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.docker ];
      serviceConfig = (dockerImage image) // {
        ExecStart = dockerRun {
          inherit
            name
            image
            environment
            volumes
            ports
            aliases
            hostname
            extraArgs
            ;
        };
        ExecStop = "-${docker} stop --time 10 ${name}";
        ExecStopPost = "-${docker} rm -f ${name}";
        Restart = "always";
        RestartSec = 5;
      };
    };
in
{
  assertions = [
    {
      assertion = lanAddress != null;
      message = "hawkBit requires my.host.address so its LAN endpoints have a specific bind address.";
    }
  ];
  systemd.tmpfiles.rules = [
    "d ${hawkbitDataRoot} 0750 root root -"
    "d ${hawkbitDataRoot}/artifactrepo 0750 root root -"
    "d ${hawkbitDataRoot}/postgres 0750 root root -"
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
  networking.firewall.allowedTCPPorts = [
    5432
    5672
    8081
    8082
    15672
  ];
  systemd.services = {
    docker-hawkbit-network = {
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "-${docker} network rm ${dockerNetwork}";
      };
      script = ''
        ${docker} network inspect ${dockerNetwork} >/dev/null 2>&1 || ${docker} network create ${dockerNetwork}
      '';
    };
    docker-hawkbit-postgres = mkDockerService {
      name = "hawkbit-postgres";
      image = "postgres:16.5";
      hostname = "postgres";
      aliases = [ "postgres" ];
      environment = {
        POSTGRES_DB = "hawkbit";
        POSTGRES_USER = "postgres";
        POSTGRES_PASSWORD = "admin";
      };
      ports = [ "${lanAddress}:5432:5432/tcp" ];
      volumes = [ "${hawkbitDataRoot}/postgres:/var/lib/postgresql/data:rw" ];
      extraArgs = [
        "--health-cmd"
        "pg_isready -d hawkbit -U postgres"
        "--health-interval"
        "20s"
        "--health-retries"
        "10"
      ];
      after = [ "docker-hawkbit-network.service" ];
      requires = [ "docker-hawkbit-network.service" ];
    };
    docker-hawkbit-rabbitmq = mkDockerService {
      name = "hawkbit-rabbitmq";
      image = "rabbitmq:4-management-alpine";
      hostname = "rabbitmq";
      aliases = [ "rabbitmq" ];
      environment = {
        RABBITMQ_DEFAULT_VHOST = "/";
        RABBITMQ_DEFAULT_USER = "guest";
        RABBITMQ_DEFAULT_PASS = "guest";
      };
      ports = [
        "${lanAddress}:15672:15672/tcp"
        "${lanAddress}:5672:5672/tcp"
      ];
      after = [ "docker-hawkbit-network.service" ];
      requires = [ "docker-hawkbit-network.service" ];
    };
    docker-hawkbit-ddi = mkDockerService {
      name = "hawkbit-ddi";
      image = "hawkbit/hawkbit-ddi-server:latest";
      aliases = [ "hawkbit-ddi" ];
      environment = databaseEnvironment;
      ports = [ "${lanAddress}:8081:8081/tcp" ];
      volumes = [ "${hawkbitDataRoot}/artifactrepo:/app/artifactrepo:rw" ];
      after = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-postgres.service"
        "docker-hawkbit-rabbitmq.service"
      ];
      requires = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-postgres.service"
        "docker-hawkbit-rabbitmq.service"
      ];
    };
    docker-hawkbit-dmf = mkDockerService {
      name = "hawkbit-dmf";
      image = "hawkbit/hawkbit-dmf-server:latest";
      aliases = [ "hawkbit-dmf" ];
      environment = databaseEnvironment;
      after = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-postgres.service"
        "docker-hawkbit-rabbitmq.service"
      ];
      requires = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-postgres.service"
        "docker-hawkbit-rabbitmq.service"
      ];
    };
    docker-hawkbit-mgmt = mkDockerService {
      name = "hawkbit-mgmt";
      image = "hawkbit/hawkbit-mgmt-server:latest";
      aliases = [ "hawkbit-mgmt" ];
      environment = mgmtEnvironment;
      ports = [ "${lanAddress}:8082:8080/tcp" ];
      volumes = [ "${hawkbitDataRoot}/artifactrepo:/app/artifactrepo:rw" ];
      after = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-postgres.service"
        "docker-hawkbit-rabbitmq.service"
      ];
      requires = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-postgres.service"
        "docker-hawkbit-rabbitmq.service"
      ];
    };
    docker-hawkbit-ui = mkDockerService {
      name = "hawkbit-ui";
      image = "ghcr.io/dogukanarat/hawkbit-ui";
      environment = {
        HAWKBIT_URL = "http://hawkbit-mgmt:8080";
      };
      ports = [ "127.0.0.1:8084:80/tcp" ];
      after = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-mgmt.service"
      ];
      requires = [
        "docker-hawkbit-network.service"
        "docker-hawkbit-mgmt.service"
      ];
    };
  };
}
