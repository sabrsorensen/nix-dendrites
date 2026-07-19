{
  inputs,
  ...
}:
{
  flake.modules.nixos.ankerctl =
    { config, lib, ... }:
    let
      serviceName = "ankerctl";
      host = "127.0.0.1";
      port = 4470;
      localAddr = "${host}:${toString port}";
      dataDir = "/opt/ankerctl/config";
      capturesDir = "/opt/ankerctl/captures";
      logsDir = "/opt/ankerctl/logs";
      ankerctlEnvSecret = "ankerctl-env";
      hasAnkerctlEnv = builtins.pathExists "${inputs.nix-secrets}/env_files/ankerctl.env";
    in
    {
      options.my.services.ankerctl.enable = lib.mkEnableOption "Ankerctl printer service";

      config = lib.mkIf config.my.services.ankerctl.enable {
        my.localDns.records = [
          { hostname = serviceName; }
        ];

        my.caddy.virtualHosts."${serviceName}.{$DOMAIN}".routes = [
          ''
            basic_auth /* {
                sorenssa {$ANKERCTL_PASSWORD}
            }
            reverse_proxy /* ${localAddr}
          ''
        ];

        networking.firewall = {
          allowedTCPPorts = [ port ];
          allowedUDPPorts = [
            32100
            32108
            32109
          ];
        };

        systemd.tmpfiles.rules = [
          "d ${dataDir} 0750 1000 1000 -"
          "d ${capturesDir} 0750 1000 1000 -"
          "d ${logsDir} 0750 1000 1000 -"
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
          image = "ghcr.io/sabrsorensen/ankerctl:chore-publish-region-image";
          environment = {
            ANKERCTL_LOG_DIR = "/logs";
            TIMELAPSE_CAPTURES_DIR = "/captures";
          };
          environmentFiles = lib.optionals hasAnkerctlEnv [
            config.sops.secrets.${ankerctlEnvSecret}.path
          ];
          extraOptions = [ "--network=host" ];
          log-driver = "journald";
          volumes = [
            "${dataDir}:/root/.ankerctl:rw"
            "${capturesDir}:/captures:rw"
            "${logsDir}:/logs:rw"
          ];
        };
      };
    };
}
