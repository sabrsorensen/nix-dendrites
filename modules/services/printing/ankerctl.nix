{
  inputs,
  ...
}:
{
  flake.modules.nixos.ankerctl =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "ankerctl";
      imageName = "ankerctl:fork";
      host = "127.0.0.1";
      port = 4470;
      localAddr = "${host}:${toString port}";
      subdomain = serviceName;
      dataDir = "/opt/ankerctl/config";
      capturesDir = "/opt/ankerctl/captures";
      logsDir = "/opt/ankerctl/logs";
      ankerctlEnvSecret = "ankerctl-env";
      src = pkgs.fetchFromGitHub {
        owner = "sabrsorensen";
        repo = "ankermake-m5-protocol";
        rev = "ed176a303259f160cd2c13c60a427be1ce2c205d";
        hash = "sha256-n7q48rIrpGjX/0ro+ej4U7RkLprqzhVUDeQaTp1JILg=";
      };
      hasAnkerctlEnv = builtins.pathExists "${inputs.nix-secrets}/env_files/ankerctl.env";
      python = pkgs.python3.override {
        packageOverrides = final: prev: {
          tinyec = final.buildPythonPackage rec {
            pname = "tinyec";
            version = "0.4.0";
            format = "setuptools";
            src = final.fetchPypi {
              inherit pname version;
              hash = "sha256-sDZKqzua9jK2TyTq+uDI5WzGS0hFZIdSYQ9I8qsFR6M=";
            };
            pythonImportsCheck = [ "tinyec" ];
          };
        };
      };
      pythonEnv = python.withPackages (
        ps: with ps; [
          click
          crcmod
          flask
          flask-sock
          paho-mqtt
          platformdirs
          pycryptodomex
          requests
          rich
          tqdm
          tinyec
          user-agents
        ]
      );
      appTree = pkgs.stdenvNoCC.mkDerivation {
        pname = "ankerctl-app";
        version = "fork";
        inherit src;
        dontBuild = true;
        installPhase = ''
          mkdir -p "$out/app"
          cp -r \
            ankerctl.py \
            cli \
            libflagship \
            ssl \
            static \
            web \
            "$out/app/"
        '';
      };
      image = pkgs.dockerTools.buildLayeredImage {
        name = "ankerctl";
        tag = "fork";
        contents = [
          appTree
          pkgs.bash
          pkgs.cacert
          pkgs.coreutils
          pkgs.ffmpeg
          pythonEnv
        ];
        config = {
          WorkingDir = "/app";
          Cmd = [
            "${pythonEnv}/bin/python"
            "/app/ankerctl.py"
            "webserver"
            "run"
          ];
          Env = [
            "HOME=/root"
            "PYTHONUNBUFFERED=1"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          ];
        };
      };
    in
    {
      my.localDns.records = [
        { hostname = subdomain; }
      ];

      my.caddy.virtualHosts."${subdomain}.{$DOMAIN}".routes = [
        ''
          basic_auth /* {
              sorenssa {$ANKERCTL_PASSWORD}
          }
          reverse_proxy /* ${localAddr}
        ''
      ];

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0750 root root -"
        "d ${capturesDir} 0750 root root -"
        "d ${logsDir} 0750 root root -"
      ];

      sops.secrets = lib.optionalAttrs hasAnkerctlEnv {
        ${ankerctlEnvSecret} = {
          owner = "root";
          group = "root";
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/env_files/ankerctl.env";
          key = "";
        };
      };

      virtualisation.oci-containers.containers.${serviceName} = {
        autoStart = true;
        image = imageName;
        imageFile = image;
        environment = {
          "ANKERCTL_LOG_DIR" = "/logs";
          "FLASK_HOST" = host;
          "FLASK_PORT" = toString port;
          "TIMELAPSE_CAPTURES_DIR" = "/captures";
        };
        environmentFiles = lib.optionals hasAnkerctlEnv [
          config.sops.secrets.${ankerctlEnvSecret}.path
        ];
        extraOptions = [
          "--network=host"
          "--pull=never"
        ];
        log-driver = "journald";
        volumes = [
          "${dataDir}:/root/.config/ankerctl:rw"
          "${capturesDir}:/captures:rw"
          "${logsDir}:/logs:rw"
        ];
      };
    };
}
