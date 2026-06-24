{
  flake.modules.nixos.podman =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.services.podman.enable = lib.mkEnableOption "Podman container runtime";

      config = lib.mkIf (config.my.host.features.containers || config.my.services.podman.enable) {
        # Enable container name DNS for all Podman networks.
        networking.firewall.interfaces =
          let
            matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
          in
          {
            "${matchAll}".allowedUDPPorts = [ 53 ];
          };

        virtualisation.podman = {
          enable = true;
          dockerCompat = true;
          # Create the default bridge network for podman
          defaultNetwork.settings.dns_enabled = true;
        };
        virtualisation.oci-containers.backend = "podman";
      };
    };
}
