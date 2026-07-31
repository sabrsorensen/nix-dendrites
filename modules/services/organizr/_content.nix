{
  cfg,
  config,
  containerIdentity,
  groupName,
  lib,
  localAddr,
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
  my.caddy.apexRoutes = lib.mkIf cfg.setAsApexBackend (
    lib.mkAfter [
      ''
        reverse_proxy /* ${localAddr}
      ''
    ]
  );
  virtualisation.oci-containers.containers.${serviceName} = {
    image = "ghcr.io/organizr/organizr";
    autoStart = true;
    environment = {
      "PUID" = lib.toString config.users.users.${serviceName}.uid;
      "PGID" = lib.toString config.users.groups.${groupName}.gid;
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${mediaCfg.configRoot}/${serviceName}:/config:rw"
    ];
    ports = [ "${localAddr}:80/tcp" ];
    labels."com.centurylinklabs.watchtower.enable" = "true";
    log-driver = "journald";
    extraOptions = map (dnsServer: "--dns=${dnsServer}") mediaCfg.dnsServers ++ [
      "--network-alias=${serviceName}"
    ];
  };
}
