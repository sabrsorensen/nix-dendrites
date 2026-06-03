{
  flake.modules.nixos.gonic =
  {
    config,
    ...
  }:
  let
    mediaCfg = config.my.media;
    serviceName = "gonic";
  in
  {
    my.media.caddy.apexRoutes = [
      ''
        redir /${serviceName} /${serviceName}/
        handle_path /${serviceName}/* {
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
        proxy-prefix = "/${serviceName}";
      };
    };
  };
}
