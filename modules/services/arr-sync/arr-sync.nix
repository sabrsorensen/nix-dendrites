{ inputs, ... }:
{
  flake.modules.nixos.arr-sync =
    args@{ config, lib, ... }:
    let
      cfg = config.my.arrSync;
      serviceName = "arr-sync";
    in
    {
      options.my.arrSync.image = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/sabrsorensen/arr-sync-webhook";
        description = "Container image for the Arr Sync webhook service.";
      };

      config = lib.mkIf config.my.host.services.arrSync (
        import ./_arr-sync.nix (args // { inherit cfg inputs serviceName; })
      );
    };
}
