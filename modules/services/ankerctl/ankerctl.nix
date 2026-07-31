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
    lib.mkIf config.my.host.services.ankerctl (
      import ./_content.nix (
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
}
