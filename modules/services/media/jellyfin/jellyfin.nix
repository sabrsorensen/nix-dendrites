{
  flake.modules.nixos.jellyfin = {
    users.users.jellyfin.group = "media";
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /jellyfin /jellyfin/
            reverse_proxy /jellyfin/* 127.0.0.1:8096
          '';
        };
      };

      jellyfin = {
        enable = true;
        openFirewall = true;
        group = "media";
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