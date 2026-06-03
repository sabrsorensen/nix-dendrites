{
  flake.modules.nixos.organizr =
    {
      config,
      lib,
      ...
    }:
    let
      groupName = "media";
      localAddr = "127.0.0.1:81";
      mediaCfg = config.my.media;
      serviceName = "organizr";
    in
    {
      users.users.${serviceName} = {
        isSystemUser = true;
        group = groupName;
      };
      my.media.caddy.apexBackend = lib.mkDefault localAddr;
      virtualisation.oci-containers.containers.${serviceName} = {
        image = "ghcr.io/organizr/organizr";
        autoStart = true;
        environment = {
          "PUID" = "${lib.toString config.users.users.${serviceName}.uid}";
          "PGID" = "${lib.toString config.users.groups.${groupName}.gid}";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${mediaCfg.configRoot}/${serviceName}:/config:rw"
        ];
        ports = [
          "${localAddr}:80/tcp"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        extraOptions = map (dnsServer: "--dns=${dnsServer}") mediaCfg.dnsServers ++ [
          "--network-alias=${serviceName}"
        ];
      };
    };
}
