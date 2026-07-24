{ ... }:
{
  flake.modules.nixos.podman =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.podman {
      # Permit DNS on the default and additional Podman bridge networks.
      networking.firewall.interfaces =
        let
          matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
        in
        {
          "${matchAll}".allowedUDPPorts = [ 53 ];
        };
      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
        defaultNetwork.settings.dns_enabled = true;
      };
      virtualisation.oci-containers.backend = "podman";
    };
}
