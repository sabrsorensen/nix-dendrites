{
  cfg,
  groupName,
  localAddr,
  ...
}:
{
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
    hardwareAcceleration = { };
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
}
