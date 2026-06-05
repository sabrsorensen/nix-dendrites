{
  flake.modules.nixos.profilarr =
    {
      config,
      lib,
      ...
    }:
    let
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
      localDomain = config.systemConstants.domain;
      groupName = "media";
      localAddr = "127.0.0.1:6868";
      mediaCfg = config.my.media;
      serviceName = "profilarr";
      containerIdentity = lib.attrByPath [
        serviceName
      ] {
        uid = 2105;
        gid = 2096;
      } mediaCfg.containerIdentities;
    in
    {
      users.users.${serviceName} = {
        isSystemUser = true;
        group = groupName;
        uid = toInt containerIdentity.uid;
      };
      my.localDns.records = [
        { hostname = serviceName; }
      ];
      my.media.caddy.virtualHosts."${serviceName}.{$DOMAIN}" = [
        ''
          reverse_proxy /* ${localAddr}
        ''
      ];
      virtualisation.oci-containers.containers.${serviceName} = {
        user = serviceName;
        image = "ghcr.io/dictionarry-hub/profilarr:2.0.7";
        autoStart = true;
        environment = {
          "PUID" = lib.toString config.users.users.${serviceName}.uid;
          "PGID" = lib.toString config.users.groups.${groupName}.gid;
          "TZ" = config.time.timeZone;
          "ORIGIN" = "https://${serviceName}.${localDomain}/";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${mediaCfg.configRoot}/${serviceName}:/config"
        ];
        ports = [
          "${localAddr}:6868/tcp"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        extraOptions = [
          "--network-alias=${serviceName}"
        ];
      };
    };
}
