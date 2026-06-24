{
  flake.modules.nixos.jellyfin =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.jellyfin;
      groupName = "media";
      localAddr = "127.0.0.1:8096";
      serviceName = "jellyfin";
    in
    {
      options.my.services.jellyfin = {
        enable = lib.mkEnableOption "Jellyfin media service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };
      };

      config = lib.mkIf cfg.enable {
        users.users.jellyfin.group = groupName;
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            reverse_proxy /${cfg.pathSegment}/* ${localAddr}
          ''
        ];
        services.jellyfin = {
          enable = true;
          openFirewall = true;
          group = groupName;
          hardwareAcceleration = {
          };
          transcoding = {
            deleteSegments = true;
            enableHardwareEncoding = true;
            hardwareDecodingCodecs = { };
            hardwareEncodingCodecs = { };
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
