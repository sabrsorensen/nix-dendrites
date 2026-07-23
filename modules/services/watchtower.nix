{ ... }:
{
  flake.modules.nixos.watchtower =
    { config, lib, ... }:
    lib.mkIf config.my.host.services.watchtower {
      assertions = [
        {
          assertion = config.my.host.features.podman;
          message = "Watchtower requires features.podman so it can use Podman's Docker-compatible socket.";
        }
      ];

      virtualisation.podman.dockerSocket.enable = true;
      virtualisation.oci-containers.containers.watchtower = {
        image = "nickfedor/watchtower";
        autoStart = true;
        volumes = [ "/run/podman/podman.sock:/var/run/docker.sock:rw" ];
        cmd = [
          "--cleanup"
          "--label-enable"
        ];
        labels."com.centurylinklabs.watchtower.enable" = "true";
        log-driver = "journald";
        extraOptions = [
          "--network-alias=watchtower"
          "--network=${config.my.media.podmanNetwork}"
        ];
      };

      systemd.services.podman-watchtower = {
        after = [ "podman-network-media.service" ];
        requires = [ "podman-network-media.service" ];
      };
    };
}
