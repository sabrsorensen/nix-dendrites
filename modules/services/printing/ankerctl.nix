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
      containerUid = 1000;
      containerGid = 1000;
      containerHome = "/home/ankerctl";
      containerConfigDir = "${containerHome}/.config/ankerctl";
      host = "127.0.0.1";
      port = 4470;
      localAddr = "${host}:${toString port}";
      subdomain = serviceName;
      dataDir = "/opt/ankerctl/config";
      capturesDir = "/opt/ankerctl/captures";
      logsDir = "/opt/ankerctl/logs";
      tempDir = "/opt/ankerctl/tmp";
      ankerctlEnvSecret = "ankerctl-env";
      src = pkgs.fetchFromGitHub {
        owner = "sabrsorensen";
        repo = "ankermake-m5-protocol";
        rev = "7a87c932b5ad37ba0ce3e30e2a8f5d96081d7877";
        hash = "sha256-9gMFvx2OWpAhVNGS5bqphqmUuRP1DYE9bw0406jacVo=";
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
          werkzeug
        ]
      );
      entrypoint = pkgs.writeShellScript "ankerctl-entrypoint.sh" ''
        set -eu

        ensure_path_ownership() {
          path="$1"

          if [ ! -d "$path" ]; then
            return 0
          fi

          mismatched_path="$(${pkgs.findutils}/bin/find "$path" -xdev \( ! -uid ${toString containerUid} -o ! -gid ${toString containerGid} \) -print -quit)"
          if [ -z "$mismatched_path" ]; then
            return 0
          fi

          echo "Repairing ankerctl ownership under $path..."
          ${pkgs.findutils}/bin/find "$path" -xdev \( ! -uid ${toString containerUid} -o ! -gid ${toString containerGid} \) \
            -exec ${pkgs.coreutils}/bin/chown ${toString containerUid}:${toString containerGid} '{}' +
        }

        if [ "$(${pkgs.coreutils}/bin/id -u)" -eq 0 ]; then
          for path in ${containerConfigDir} /captures /logs /tmp; do
            ensure_path_ownership "$path"
          done

          exec ${pkgs.util-linux}/bin/setpriv \
            --reuid ${toString containerUid} \
            --regid ${toString containerGid} \
            --clear-groups \
            "$@"
        fi

        exec "$@"
      '';
      appTree = pkgs.stdenvNoCC.mkDerivation {
        pname = "ankerctl-app";
        version = "fork";
        inherit src;
        dontBuild = true;
        installPhase = ''
          mkdir -p "$out/app"
          mkdir -p "$out${containerConfigDir}"
          cp -r \
            ankerctl.py \
            cli \
            libflagship \
            ssl \
            static \
            web \
            "$out/app/"
          cp ${entrypoint} "$out/app/ankerctl-entrypoint.sh"
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
          pkgs.findutils
          pkgs.util-linux
          pythonEnv
        ];
        config = {
          WorkingDir = "/app";
          Entrypoint = [ "/app/ankerctl-entrypoint.sh" ];
          Cmd = [
            "${pythonEnv}/bin/python"
            "/app/ankerctl.py"
            "webserver"
            "run"
            "--host"
            "0.0.0.0"
          ];
          Env = [
            "HOME=${containerHome}"
            "PYTHONUNBUFFERED=1"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          ];
          Healthcheck = {
            Test = [
              "CMD"
              "${pythonEnv}/bin/python"
              "-c"
              "import os, urllib.request; host=os.getenv('FLASK_HOST','127.0.0.1'); host='127.0.0.1' if host in ('0.0.0.0','::','') else host; urllib.request.urlopen(f'http://{host}:{os.getenv(\"FLASK_PORT\",\"4470\")}/api/health', timeout=4)"
            ];
            Interval = 30000000000;
            Timeout = 5000000000;
            StartPeriod = 20000000000;
            Retries = 3;
          };
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
        "d ${dataDir} 0750 ${toString containerUid} ${toString containerGid} -"
        "d ${capturesDir} 0750 ${toString containerUid} ${toString containerGid} -"
        "d ${logsDir} 0750 ${toString containerUid} ${toString containerGid} -"
        "d ${tempDir} 1777 ${toString containerUid} ${toString containerGid} -"
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
          "TEMP" = "/tmp";
          "TIMELAPSE_CAPTURES_DIR" = "/captures";
          "TMP" = "/tmp";
          "TMPDIR" = "/tmp";
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
          "${dataDir}:${containerConfigDir}:rw"
          "${capturesDir}:/captures:rw"
          "${logsDir}:/logs:rw"
          "${tempDir}:/tmp:rw"
        ];
      };
    };
}
