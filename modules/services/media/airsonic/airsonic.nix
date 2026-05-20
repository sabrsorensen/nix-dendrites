{
  flake.modules.nixos.airsonic =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  {
    environment.systemPackages = with pkgs; [
      ffmpeg
      flac
      lame
    ];
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          #redir /airsonic /airsonic/
          #reverse_proxy /airsonic/* ${config.services.airsonic.listenAddress}:${lib.toString config.services.airsonic.port}
          extraConfig = ''
            redir /airsonic /airsonic/
            reverse_proxy /airsonic/* 127.0.0.1:4040
          '';
        };
      };

      #airsonic = {
      #  enable = true;
      #  contextPath = "/airsonic";
      #  virtualHost = null;
      #  maxMemory = 512;
      #  jvmOptions = [
      #    "-Xms256m"
      #    "-Dserver.forward-headers-strategy=framework"
      #    "-Dserver.use-forward-headers=true" # needed since we're using caddy, not nginx's virtualHost
      #  ];
      #  transcoders = [
      #    "${pkgs.ffmpeg.bin}/bin/ffmpeg"
      #    "${pkgs.flac.bin}/bin/flac"
      #    "${pkgs.lame}/bin/lame"
      #  ];
      #};
    };
    virtualisation.oci-containers.containers."airsonic" = {
      image = "lscr.io/linuxserver/airsonic-advanced:latest";
      autoStart = true;
      environment = {
        "PGID" = "978";
        "PUID" = "1000";
        "JAVA_OPTS" = "-Xmx256m -Xms256m -Dserver.forward-headers-strategy=framework -Dserver.context-path=/airsonic/";
        "CONTEXT_PATH" = "/airsonic";
        "TZ" = "America/Boise";
        "LOG4J_FORMAT_MSG_NO_LOOKUPS" = "true";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/opt/airsonic/:/config"
        "/AnomalyRealm/media/music/ready_to_stream:/media"
        "/AnomalyRealm/media/music/ready_to_stream:/music"
        "/AnomalyRealm/media/music/source_files/Google Music/:/old_google_music"
        "/AnomalyRealm/media/music/podcasts:/podcasts"
        "/AnomalyRealm/media/music/playlists:/playlists"
      ];
      ports = [
        "127.0.0.1:4040:4040/tcp"
      ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "true";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=airsonic"
      ];
    };
  };
}