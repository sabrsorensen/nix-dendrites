{ ... }:
{
  flake.modules.nixos.jellyfin =
    { config, lib, ... }:
    let
      cfg = config.my.jellyfin;
    in
    {
      options.my.jellyfin.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "jellyfin";
        description = "Path below the apex domain used for Jellyfin.";
      };

      config = lib.mkIf config.my.host.services.jellyfin {
        users.users.jellyfin.group = "media";
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            reverse_proxy /${cfg.pathSegment}/* 127.0.0.1:8096
          ''
        ];
        services.jellyfin = {
          enable = true;
          openFirewall = true;
          group = "media";
          transcoding = {
            deleteSegments = true;
            enableHardwareEncoding = true;
            enableIntelLowPowerEncoding = true;
            enableSubtitleExtraction = true;
            enableToneMapping = true;
            maxConcurrentStreams = null;
            threadCount = null;
            throttleTranscoding = false;
          };
        };
      };
    };
}
