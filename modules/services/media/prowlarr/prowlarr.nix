{ ... }:
{
  flake.modules.nixos.prowlarr =
    {
      lib,
      ...
    }:
    let
      arr = import ../_arr { inherit lib; };
      bindAddr = "127.0.0.1";
      port = 9696;
      serviceName = "prowlarr";
    in
    arr.mkModule {
      inherit serviceName;
      setUserGroup = false;
      routeSpecs = [
        {
          inherit bindAddr port;
        }
      ];
      serviceConfig = {
        enable = true;
        openFirewall = false;
        settings.server = {
          urlbase = "/${serviceName}";
          inherit port;
          bindaddress = bindAddr;
        };
      };
    };
}
