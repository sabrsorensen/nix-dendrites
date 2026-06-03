{
  flake.modules.nixos.virtualisation =
    {
      config,
      ...
    }:
    {
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
        # Create the default bridge network for podman
        defaultNetwork.settings.dns_enabled = true;
      };
      virtualisation.oci-containers.backend = "podman";
    };
}
