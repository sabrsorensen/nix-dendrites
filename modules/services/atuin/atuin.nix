{ ... }:
{
  flake.modules.nixos.atuin-server =
    args@{ config, lib, ... }:
    let
      cfg = config.my.atuin;
    in
    {
      options.my.atuin = {
        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = "atuin";
          description = "Path below the apex domain used for Atuin synchronization.";
        };
        openRegistration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Allow unauthenticated Atuin account registration.";
        };
        siteHostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional dedicated local hostname; null publishes Atuin at the apex path.";
        };
      };

      options.my.host.services.atuinServer = lib.mkEnableOption "Atuin history-sync server";
      config = lib.mkIf config.my.host.services.atuinServer (
        import ./_atuin.nix (args // { inherit cfg; })
      );
    };
}
