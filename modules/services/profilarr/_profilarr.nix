{
  cfg,
  config,
  containerIdentity,
  groupName,
  lib,
  localAddr,
  localDomain,
  mediaCfg,
  serviceName,
  ...
}:
let
  toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
in
{
  users.users.${serviceName} = {
    isSystemUser = true;
    group = groupName;
    uid = toInt containerIdentity.uid;
  };
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* ${localAddr}
    ''
  ];
  virtualisation.oci-containers.containers.${serviceName} = {
    image = "ghcr.io/dictionarry-hub/profilarr:2.0.8";
    autoStart = true;
    environment = {
      "PUID" = lib.toString config.users.users.${serviceName}.uid;
      "PGID" = lib.toString config.users.groups.${groupName}.gid;
      "TZ" = config.time.timeZone;
      "ORIGIN" = if cfg.origin != null then cfg.origin else "https://${cfg.hostName}.${localDomain}/";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${mediaCfg.configRoot}/${serviceName}:/config"
    ];
    ports = [ "${localAddr}:6868/tcp" ];
    labels."com.centurylinklabs.watchtower.enable" = "true";
    log-driver = "journald";
    extraOptions = [ "--network-alias=${serviceName}" ];
  };
}
