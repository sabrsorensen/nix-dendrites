{ ... }:
{
  flake.modules.nixos.organizr =
    { config, lib, ... }:
    let
      serviceName = "organizr";
      identity = lib.attrByPath [ serviceName ] {
        uid = 2103;
        gid = 2096;
      } config.my.media.containerIdentities;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
    in
    {
      options.my.organizr.setAsApexBackend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Route otherwise-unmatched apex requests to Organizr.";
      };

      config = lib.mkIf config.my.host.services.organizr {
        users.users.${serviceName} = {
          isSystemUser = true;
          group = "media";
          uid = toInt identity.uid;
        };
        systemd.tmpfiles.rules = [
          "d ${config.my.media.configRoot}/${serviceName} 0750 ${serviceName} media -"
        ];
        my.caddy.apexRoutes = lib.mkIf config.my.organizr.setAsApexBackend (
          lib.mkAfter [
            "reverse_proxy /* 127.0.0.1:81"
          ]
        );
        virtualisation.oci-containers.containers.${serviceName} = {
          image = "ghcr.io/organizr/organizr";
          autoStart = true;
          environment = {
            PUID = toString config.users.users.${serviceName}.uid;
            PGID = toString config.users.groups.media.gid;
          };
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${config.my.media.configRoot}/${serviceName}:/config:rw"
          ];
          ports = [ "127.0.0.1:81:80/tcp" ];
          labels."com.centurylinklabs.watchtower.enable" = "true";
          log-driver = "journald";
          extraOptions = map (dnsServer: "--dns=${dnsServer}") config.my.media.dnsServers ++ [
            "--network-alias=${serviceName}"
          ];
        };
      };
    };
}
