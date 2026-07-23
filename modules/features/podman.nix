{ ... }:
{
  flake.modules.nixos.podman =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.podman {
      virtualisation.podman.enable = true;
      virtualisation.oci-containers.backend = "podman";
    };
}
