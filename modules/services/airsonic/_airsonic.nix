{
  cfg,
  config,
  containerIdentity,
  groupName,
  lib,
  localAddr,
  mediaCfg,
  pkgs,
  serviceName,
  ...
}:
let
  toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
in
{
  users.users.${serviceName} = {
    isSystemUser = true;
    group = groupName;
    uid = toInt containerIdentity.uid;
  };
  environment.systemPackages = with pkgs; [
    ffmpeg
    flac
    lame
  ];
  my.caddy.apexRoutes = [
    ''
      redir /${cfg.pathSegment} /${cfg.pathSegment}/
      reverse_proxy /${cfg.pathSegment}/* ${localAddr}
    ''
  ];
  virtualisation.oci-containers.containers.${serviceName} = {
    image = "ghcr.io/airsonic-pulse/airsonic-pulse:13.2.0";
    autoStart = true;
    environment = {
      "PUID" = lib.toString config.users.users.${serviceName}.uid;
      "PGID" = lib.toString config.users.groups.${groupName}.gid;
      "JAVA_OPTS" =
        "-Xmx2048m -Xms1024m -Dserver.forward-headers-strategy=framework -Dserver.context-path=/${cfg.pathSegment}/";
      "CONTEXT_PATH" = "/${cfg.pathSegment}";
      "TZ" = config.time.timeZone;
      "LOG4J_FORMAT_MSG_NO_LOOKUPS" = "true";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${mediaCfg.configRoot}/${serviceName}:/var/airsonic"
      "${mediaCfg.dataRoot}/music/ready_to_stream:/music"
      "${mediaCfg.dataRoot}/music/untagged_imports:/music/untagged_imports"
      "${mediaCfg.dataRoot}/music/source_files/Google Music/:/old_google_music"
      "${mediaCfg.dataRoot}/music/podcasts:/podcasts"
      "${mediaCfg.dataRoot}/music/playlists:/playlists"
    ];
    ports = [
      "${localAddr}:4040/tcp"
    ];
    labels = { };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=${serviceName}"
    ];
  };
}
