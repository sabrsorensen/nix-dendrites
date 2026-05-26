{
  flake.modules.nixos.airsonic =
  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    groupName = "media";
    localAddr = "127.0.0.1:4040";
    serviceName = "airsonic";
  in
  {
    users.users.${serviceName} = {
      isSystemUser = true;
      group = groupName;
    };
    environment.systemPackages = with pkgs; [
      ffmpeg
      flac
      lame
    ];
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          #redir /${serviceName} /${serviceName}/
          #reverse_proxy /${serviceName}/* ${config.services.${serviceName}.listenAddress}:${lib.toString config.services.${serviceName}.port}
          extraConfig = ''
            redir /${serviceName} /${serviceName}/
            reverse_proxy /${serviceName}/* ${localAddr}
          '';
        };
      };

      #airsonic = {
      #  enable = true;
      #  contextPath = "/${serviceName}";
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
    virtualisation.oci-containers.containers.${serviceName} = {
      image = "lscr.io/linuxserver/airsonic-advanced:latest";
      autoStart = true;
      environment = {
        "PUID" = "${lib.toString config.users.users.${serviceName}.uid}";
        "PGID" = "${lib.toString config.users.groups.${groupName}.gid}";
        "JAVA_OPTS" = "-Xmx256m -Xms256m -Dserver.forward-headers-strategy=framework -Dserver.context-path=/${serviceName}/";
        "CONTEXT_PATH" = "/${serviceName}";
        "TZ" = "America/Boise";
        "LOG4J_FORMAT_MSG_NO_LOOKUPS" = "true";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/opt/${serviceName}/:/config"
        "/AnomalyRealm/media/music/ready_to_stream:/media"
        "/AnomalyRealm/media/music/ready_to_stream:/music"
        "/AnomalyRealm/media/music/source_files/Google Music/:/old_google_music"
        "/AnomalyRealm/media/music/podcasts:/podcasts"
        "/AnomalyRealm/media/music/playlists:/playlists"
      ];
      ports = [
        "${localAddr}:4040/tcp"
      ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "true";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=${serviceName}"
      ];
    };
  };
}