{
  config,
  cfg,
  domain,
  hawkbitIdentity,
  inputs,
  lib,
  pkgs,
  toInt,
  ...
}:
let
  lanAddress = config.my.host.address;
  docker = "${pkgs.docker}/bin/docker";
  dockerNetwork = "hawkbit";
  hawkbitVersion = "1.0.4";
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
  # Admin/cushychicken passwords are supplied at runtime via envFile (see
  # sops.secrets.hawkbit_env below), not baked into this derivation: a plain
  # Nix value here would end up readable in the store and in `docker inspect`
  # output for every host that evaluates this module.
  mgmtEnvironment = databaseEnvironment // {
    HAWKBIT_SECURITY_USER_ADMIN_TENANT = "DEFAULT";
    HAWKBIT_SECURITY_USER_ADMIN_ROLES = "TENANT_ADMIN";
    HAWKBIT_SECURITY_USER_CUSHYCHICKEN_TENANT = "DEFAULT";
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
      envFile ? null,
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
      ++ lib.optionals (envFile != null) [
        "--env-file"
        envFile
      ]
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
      envFile ? null,
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
            envFile
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
  sops.secrets.hawkbit_env = {
    owner = "root";
    group = "root";
    mode = "0400";
    format = "dotenv";
    sopsFile = "${inputs.nix-secrets}/env_files/hawkbit.env";
    key = "";
  };
  systemd.tmpfiles.rules = [
    "d ${hawkbitDataRoot} 0750 root root -"
    "d ${hawkbitDataRoot}/artifactrepo 0750 1000 101 -"
    "d ${hawkbitDataRoot}/postgres 0750 999 999 -"
  ];
  users.users = {
    hawkbit = {
      isSystemUser = true;
      group = "media";
      uid = toInt hawkbitIdentity.uid;
    };
  };
  my.localDns.records = [
    { hostname = cfg.hostName; }
    { hostname = "hbdemodevice"; }
  ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* 127.0.0.1:8084 {
        header_up -Accept-Encoding
      }
    ''
  ];
  # RPi4 A/B OTA proof-of-concept target: BusyBox httpd on the device
  # serves a page identifying which deployed image is currently booted,
  # a visible signal that a hawkBit-driven update actually took effect.
  my.caddy.virtualHosts."hbdemodevice.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* 192.168.1.5:80
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
      image = "rabbitmq:3.13.7-management-alpine";
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
      image = "hawkbit/hawkbit-ddi-server:${hawkbitVersion}";
      aliases = [ "hawkbit-ddi" ];
      environment = databaseEnvironment // {
        # System-wide default device poll interval, for a faster demo/test
        # feedback loop than the 5-minute default. minPollingTime must also
        # drop below pollingTime or the requested interval gets clamped
        # back up to its (also 00:00:30) default floor.
        HAWKBIT_CONTROLLER_POLLINGTIME = "00:00:20";
        HAWKBIT_CONTROLLER_MINPOLLINGTIME = "00:00:10";
      };
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
      image = "hawkbit/hawkbit-dmf-server:${hawkbitVersion}";
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
      image = "hawkbit/hawkbit-mgmt-server:${hawkbitVersion}";
      aliases = [ "hawkbit-mgmt" ];
      environment = mgmtEnvironment;
      envFile = config.sops.secrets.hawkbit_env.path;
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
