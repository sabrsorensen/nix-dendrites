{ ... }:
{
  flake.modules.nixos.moria =
    args@{ config, lib, ... }:
    let
      serviceName = "moria";
      port = 7777;
      dataDir = "/opt/moria/server";
    in
    {
      options.my.host.services.moria = lib.mkEnableOption "Return to Moria dedicated server";
      config = lib.mkIf config.my.host.services.moria (
        import ./_moria.nix (
          args
          // {
            inherit
              dataDir
              port
              serviceName
              ;
          }
        )
      );
    };
}
