{
  flake.modules.nixos.profilarr =
  {
    config,
    ...
  }:
  let
    readBuildValue =
      path:
      builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
    localDomain = readBuildValue "domain.txt";
  in
  {
    services = {
      caddy = {
        virtualHosts."profilarr.{$DOMAIN}" = {
          extraConfig = ''
            reverse_proxy /* 127.0.0.1:6868
          '';
        };
      };
    };
    virtualisation.oci-containers.containers."profilarr" = {
      #user = "sam";
      image = "ghcr.io/dictionarry-hub/profilarr:latest";
      autoStart = true;
      pull = "newer";
      environment = {
        "PGID" = "978";
        "PUID" = "1000";
        "TZ" = "America/Boise";
        "ORIGIN" = "https://profilarr.${localDomain}/";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/opt/profilarr/:/config"
      ];
      ports = [
        "127.0.0.1:6868:6868/tcp"
      ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "true";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=profilarr"
      ];
    };
  };
}