{ ... }:
{
  flake.modules.nixos.ankerctl =
    args@{ config, lib, ... }:
    let
      serviceName = "ankerctl";
      port = 4470;
      dataDir = "/opt/ankerctl/config";
      capturesDir = "/opt/ankerctl/captures";
      logsDir = "/opt/ankerctl/logs";
      localAddr = "127.0.0.1:${lib.toString port}";
    in
    {
      options.my.host.services.ankerctl = lib.mkEnableOption "AnkerCtl printer-control service";
      config = lib.mkIf config.my.host.services.ankerctl (
        import ./_ankerctl.nix (
          args
          // {
            inherit
              capturesDir
              dataDir
              localAddr
              logsDir
              port
              serviceName
              ;
          }
        )
      );
    };
}
