{ ... }:
{
  flake.modules.nixos.gonic =
    { config, lib, ... }:
    let
      cfg = config.my.gonic;
    in
    {
      options.my.gonic.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "gonic";
        description = "Path below the apex domain used for Gonic.";
      };

      config = lib.mkIf config.my.host.services.gonic {
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
              "${config.my.media.dataRoot}/music/ready_to_stream/casey_library"
              "${config.my.media.dataRoot}/music/ready_to_stream/kids_library"
              "${config.my.media.dataRoot}/music/ready_to_stream/our_library"
              "${config.my.media.dataRoot}/music/ready_to_stream/sam_library"
              "${config.my.media.dataRoot}/music/source_files/Google_Music"
            ];
            playlists-path = [ "${config.my.media.dataRoot}/music/playlists" ];
            podcast-path = [ "${config.my.media.dataRoot}/music/podcasts" ];
            proxy-prefix = "/${cfg.pathSegment}";
          };
        };
      };
    };
}
