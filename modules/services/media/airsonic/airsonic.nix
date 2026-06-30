{
  flake.modules.nixos.airsonic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.airsonic;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
      groupName = "media";
      localAddr = "127.0.0.1:4040";
      mediaCfg = config.my.media;
      serviceName = "airsonic";
      containerIdentity =
        lib.attrByPath
          [
            serviceName
          ]
          {
            uid = 2101;
            gid = 2096;
          }
          mediaCfg.containerIdentities;
    in
    {
      options.my.services.airsonic = {
        enable = lib.mkEnableOption "Airsonic media service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };
      };

      config = lib.mkIf cfg.enable {
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
          image = "lscr.io/linuxserver/airsonic-advanced:11.1.4-ls183";
          autoStart = true;
          environment = {
            "PUID" = lib.toString config.users.users.${serviceName}.uid;
            "PGID" = lib.toString config.users.groups.${groupName}.gid;
            "JAVA_OPTS" =
              "-Xmx256m -Xms256m -Dserver.forward-headers-strategy=framework -Dserver.context-path=/${cfg.pathSegment}/";
            "CONTEXT_PATH" = "/${cfg.pathSegment}";
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
    };
}
