{
  flake.modules.nixos.gonic =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.gonic;
      mediaCfg = config.my.media;
      serviceName = "gonic";
    in
    {
      options.my.services.gonic = {
        enable = lib.mkEnableOption "Gonic media service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };
      };

      config = lib.mkIf cfg.enable {
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            handle_path /${cfg.pathSegment}/* {
              reverse_proxy ${config.services.gonic.settings.listen-addr}
            }
          ''
        ];
        services.gonic = {
          enable = true;
          settings = {
            music-path = [
              "${mediaCfg.dataRoot}/music/ready_to_stream/casey_library"
              "${mediaCfg.dataRoot}/music/ready_to_stream/kids_library"
              "${mediaCfg.dataRoot}/music/ready_to_stream/our_library"
              "${mediaCfg.dataRoot}/music/ready_to_stream/sam_library"
              "${mediaCfg.dataRoot}/music/source_files/Google_Music"
            ];
            playlists-path = [
              "${mediaCfg.dataRoot}/music/playlists"
            ];
            podcast-path = [
              "${mediaCfg.dataRoot}/music/podcasts"
            ];
            proxy-prefix = "/${cfg.pathSegment}";
          };
        };
      };
    };
}
