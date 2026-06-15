{
  flake.modules.nixos.netbird-client = {
    services.netbird = {
      enable = true;

      # Keep reverse-path filtering in loose mode for overlay tunnel traffic.
      useRoutingFeatures = "client";

      # Be explicit about peer reachability defaults.
      clients.default = {
        openFirewall = true;
        openInternalFirewall = true;
      };
    };
  };
}
