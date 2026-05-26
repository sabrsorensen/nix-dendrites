{
  flake.modules.nixos.jellyfin =
  {
    ...
  }:
  let
    groupName = "media";
    localAddr = "127.0.0.1:8096";
    serviceName = "jellyfin";
  in
  {
    users.users.jellyfin.group = groupName;
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /${serviceName} /${serviceName}/
            reverse_proxy /${serviceName}/* ${localAddr}
          '';
        };
      };

      jellyfin = {
        enable = true;
        openFirewall = true;
        group = groupName;
        #cacheDir
        #configDir
        #dataDir
        #logDir
        hardwareAcceleration = {
          #enable = true;
          #device =
          #type
        };
        transcoding = {
          deleteSegments = true;
          enableHardwareEncoding = true;
          hardwareDecodingCodecs = {};
          hardwareEncodingCodecs = {};
          enableIntelLowPowerEncoding = true;
          enableSubtitleExtraction = true;
          enableToneMapping = true;
          #encodingPreset = "auto";
          #h264Crf = 23;
          #h265Crf = 28;
          maxConcurrentStreams = null;
          threadCount = null;
          throttleTranscoding = false;
        };
      };
    };
  };
}