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
    serviceName = "organizr";
  in
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            reverse_proxy /* ${localAddr}
          '';
        };
      };
    };
    users.users.${serviceName} = {
      isSystemUser = true;
      group = groupName;
    };
    virtualisation.oci-containers.containers.${serviceName} = {
      image = "ghcr.io/organizr/organizr";
      autoStart = true;
      environment = {
        "PUID" = "${lib.toString config.users.users.${serviceName}.uid}";
        "PGID" = "${lib.toString config.users.groups.${groupName}.gid}";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/opt/${serviceName}/:/config:rw"
      ];
      ports = [
        "${localAddr}:80/tcp"
      ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "true";
      };
      log-driver = "journald";
      extraOptions = [
        "--dns=192.168.1.3"
        "--dns=192.168.1.4"
        "--network-alias=${serviceName}"
      ];
    };
  };
}