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
    mediaCfg = config.my.media;
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
    my.media.caddy.apexRoutes = [
      ''
        redir /${serviceName} /${serviceName}/
        reverse_proxy /${serviceName}/* ${localAddr}
      ''
    ];
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
    virtualisation.oci-containers.containers.${serviceName} = {
      image = "lscr.io/linuxserver/airsonic-advanced:11.1.4-ls183";
      autoStart = true;
      environment = {
        "PUID" = "${lib.toString config.users.users.${serviceName}.uid}";
        "PGID" = "${lib.toString config.users.groups.${groupName}.gid}";
        "JAVA_OPTS" = "-Xmx256m -Xms256m -Dserver.forward-headers-strategy=framework -Dserver.context-path=/${serviceName}/";
        "CONTEXT_PATH" = "/${serviceName}";
        "TZ" = config.time.timeZone;
        "LOG4J_FORMAT_MSG_NO_LOOKUPS" = "true";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${mediaCfg.configRoot}/${serviceName}:/config"
        "${mediaCfg.dataRoot}/music/ready_to_stream:/media"
        "${mediaCfg.dataRoot}/music/ready_to_stream:/music"
        "${mediaCfg.dataRoot}/music/source_files/Google Music/:/old_google_music"
        "${mediaCfg.dataRoot}/music/podcasts:/podcasts"
        "${mediaCfg.dataRoot}/music/playlists:/playlists"
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
