{
  cfg,
  localAddr,
  port,
  ...
}:
{
  my.caddy.apexRoutes = [
    ''
      redir /${cfg.pathSegment} /${cfg.pathSegment}/
      handle_path /${cfg.pathSegment}/* {
        reverse_proxy ${localAddr}
      }
    ''
  ];

  services.ombi = {
    enable = true;
    openFirewall = false;
    inherit port;
  };
}
