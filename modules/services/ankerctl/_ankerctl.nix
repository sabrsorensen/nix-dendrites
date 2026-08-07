{
  capturesDir,
  dataDir,
  lib,
  localAddr,
  logsDir,
  port,
  serviceName,
  ...
}:
{
  my.localDns.records = [ { hostname = serviceName; } ];
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
  virtualisation.oci-containers.containers.${serviceName} = {
    autoStart = true;
    image = "ghcr.io/django1982/ankermake-m5-protocol:1.11.0";
    environment = {
      ANKERCTL_LOG_DIR = "/logs";
      TIMELAPSE_CAPTURES_DIR = "/captures";
    };
    environmentFiles = [ ];
    extraOptions = [ "--network=host" ];
    log-driver = "journald";
    ports = [ "0.0.0.0:${lib.toString port}:${lib.toString port}" ];
    volumes = [
      "${dataDir}:/home/ankerctl/.config/ankerctl:rw"
      "${capturesDir}:/captures:rw"
      "${logsDir}:/logs:rw"
    ];
  };
}
