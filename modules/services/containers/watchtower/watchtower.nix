{
  flake.modules.nixos.watchtower = {
    virtualisation.oci-containers.containers."watchtower" = {
      image = "nickfedor/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:rw"
      ];
      cmd = [ "--cleanup" "--label-enable" ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "true";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=watchtower"
        "--network=media"
      ];
    };
  };
}