{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.nextcloud =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.nextcloud;
    in
    {
      options.my.nextcloud = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "cloud";
          description = "Public hostname for the Nextcloud instance.";
        };
        collaboraHostName = lib.mkOption {
          type = lib.types.str;
          default = "office";
          description = "Public hostname for the Collabora Online instance.";
        };
        dataDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/nextcloud";
          description = "Persistent Nextcloud configuration and user-data directory.";
        };
      };

      options.my.host.services.nextcloud = lib.mkEnableOption "Nextcloud with Collabora Online";
      config = lib.mkIf config.my.host.services.nextcloud (
        import ./_nextcloud.nix (
          args
          // {
            inherit
              cfg
              domain
              inputs
              pkgs
              ;
          }
        )
      );
    };
}
