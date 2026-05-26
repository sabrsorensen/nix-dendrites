{
  flake.modules.nixos.gonic =
  {
    config,
    ...
  }:
  let
    serviceName = "gonic";
  in
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /${serviceName} /${serviceName}/
            handle_path /${serviceName}/* {
              reverse_proxy ${config.services.gonic.settings.listen-addr}
            }
          '';
        };
      };

      gonic = {
        enable = true;
        settings = {
          music-path = [
            "/AnomalyRealm/media/music/ready_to_stream/casey_library"
            "/AnomalyRealm/media/music/ready_to_stream/kids_library"
            "/AnomalyRealm/media/music/ready_to_stream/our_library"
            "/AnomalyRealm/media/music/ready_to_stream/sam_library"
            "/AnomalyRealm/media/music/source_files/Google_Music"
          ];
          playlists-path = [
            "/AnomalyRealm/media/music/playlists"
          ];
          podcast-path = [
            "/AnomalyRealm/media/music/podcasts"
          ];
          proxy-prefix = "/${serviceName}";
        };
      };
    };
  };
}