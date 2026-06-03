{
  flake.modules.nixos.prowlarr =
  {
    config,
    lib,
    ...
  }:
  let
  arr = import ../_arr/lib.nix { inherit lib; };
    bindAddr = "127.0.0.1";
    port = 9696;
    localAddr = "${bindAddr}:${lib.toString port}";
    serviceName = "prowlarr";
  in
  {
    my.media.caddy.apexRoutes = [
      (arr.mkThemeParkRoute {
        inherit localAddr serviceName;
      })
    ];

    services.prowlarr = {
      enable = true;
      openFirewall = false;
      settings.server = {
        urlbase = "/${serviceName}";
        port = port;
        bindaddress = bindAddr;
      };
    };
  };
}
