{
  flake.modules.nixos.netbird-client =
    { config, lib, ... }:
    {
      options.my.services.netbird.client.enable = lib.mkEnableOption "NetBird client";

      config = lib.mkIf config.my.services.netbird.client.enable {
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
    };
}
