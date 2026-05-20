{
  flake.modules.nixos.organizr = {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            reverse_proxy /* 127.0.0.1:81
          '';
        };
      };
    };
    virtualisation.oci-containers.containers."organizr" = {
      image = "ghcr.io/organizr/organizr";
      autoStart = true;
      environment = {
        "PGID" = "996";
        "PUID" = "1000";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/opt/organizr/:/config:rw"
      ];
      ports = [
        "127.0.0.1:81:80/tcp"
      ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "true";
      };
      log-driver = "journald";
      extraOptions = [
        "--dns=192.168.1.3"
        "--dns=192.168.1.4"
        "--network-alias=organizr"
      ];
    };
  };
}