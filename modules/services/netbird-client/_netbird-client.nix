{ }:
{
  services.netbird = {
    enable = true;
    # Loose reverse-path filtering is required for overlay tunnel traffic.
    useRoutingFeatures = "client";
    clients.default = {
      openFirewall = true;
      openInternalFirewall = true;
    };
  };
}
