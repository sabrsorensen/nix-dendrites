{ ... }:
{
  flake.modules.nixos.airsonic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "airsonic";
      cfg = config.my.airsonic;
      identity = lib.attrByPath [ serviceName ] {
        uid = 2101;
        gid = 2096;
      } config.my.media.containerIdentities;
      toInt = value: if builtins.isInt value then value else builtins.fromJSON value;
    in
    {
      options.my.airsonic.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = serviceName;
        description = "Path below the apex domain used for Airsonic.";
      };

      config = lib.mkIf config.my.host.services.airsonic {
        users.users.${serviceName} = {
          isSystemUser = true;
          group = "media";
          uid = toInt identity.uid;
        };
        environment.systemPackages = with pkgs; [
          ffmpeg
          flac
          lame
        ];
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            reverse_proxy /${cfg.pathSegment}/* 127.0.0.1:4040
          ''
        ];
        virtualisation.oci-containers.containers.${serviceName} = {
          image = "ghcr.io/airsonic-pulse/airsonic-pulse:13.2.0";
          autoStart = true;
          environment = {
            PUID = toString config.users.users.${serviceName}.uid;
            PGID = toString config.users.groups.media.gid;
            JAVA_OPTS = "-Xmx2048m -Xms1024m -Dserver.forward-headers-strategy=framework -Dserver.context-path=/${cfg.pathSegment}/";
            CONTEXT_PATH = "/${cfg.pathSegment}";
            TZ = config.time.timeZone;
            LOG4J_FORMAT_MSG_NO_LOOKUPS = "true";
          };
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${config.my.media.configRoot}/${serviceName}:/var/airsonic"
            "${config.my.media.dataRoot}/music/ready_to_stream:/music"
            "${config.my.media.dataRoot}/music/untagged_imports:/music/untagged_imports"
            "${config.my.media.dataRoot}/music/source_files/Google Music/:/old_google_music"
            "${config.my.media.dataRoot}/music/podcasts:/podcasts"
            "${config.my.media.dataRoot}/music/playlists:/playlists"
          ];
          ports = [ "127.0.0.1:4040:4040/tcp" ];
          log-driver = "journald";
          extraOptions = [ "--network-alias=${serviceName}" ];
        };
      };
    };
}
