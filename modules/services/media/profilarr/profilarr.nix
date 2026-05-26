{
  flake.modules.nixos.profilarr =
  {
    config,
    lib,
    ...
  }:
  let
    readBuildValue =
      path:
      builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
    localDomain = readBuildValue "domain.txt";
    groupName = "media";
    localAddr = "127.0.0.1:6868";
    serviceName = "profilarr";
  in
  {
    users.users.${serviceName} = {
      isSystemUser = true;
      group = groupName;
    };
    services = {
      caddy = {
        virtualHosts."${serviceName}.{$DOMAIN}" = {
          extraConfig = ''
            reverse_proxy /* ${localAddr}
          '';
        };
      };
    };
    virtualisation.oci-containers.containers.${serviceName} = {
      user = serviceName;
      image = "ghcr.io/dictionarry-hub/profilarr:latest";
      autoStart = true;
      pull = "newer";
      environment = {
        "PUID" = "${lib.toString config.users.users.${serviceName}.uid}";
        "PGID" = "${lib.toString config.users.groups.${groupName}.gid}";
        "TZ" = "America/Boise";
        "ORIGIN" = "https://${serviceName}.${localDomain}/";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/opt/${serviceName}/:/config"
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