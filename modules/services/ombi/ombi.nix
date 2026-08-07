{ ... }:
{
  flake.modules.nixos.ombi =
    args@{ config, lib, ... }:
    let
      cfg = config.my.ombi;
      bindAddr = "127.0.0.1";
      port = 5000;
      localAddr = "${bindAddr}:${lib.toString port}";
    in
    {
      options.my.ombi.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "ombi";
        description = "Path below the apex domain used for Ombi.";
      };

      config = lib.mkIf config.my.host.services.ombi (
        import ./_ombi.nix (args // { inherit cfg localAddr port; })
      );
    };
}
