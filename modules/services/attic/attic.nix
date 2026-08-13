{ inputs, ... }:
{
  flake.modules.nixos.attic =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.attic;
      envSecretFile = "${inputs.nix-secrets}/env_files/atticd.env";
      clientConfigHome = "/var/lib/atticd/client-config";
      domain = builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile "${inputs.nix-secrets}/domain.txt"
      );
      cacheEndpoint = "https://${cfg.hostName}.${domain}/${cfg.cacheName}";
      localApiEndpoint = "http://127.0.0.1:8080";
      targetPattern = lib.concatStringsSep "|" (
        map lib.escapeRegex (map lib.toLower cfg.autoPush.targetBasenames)
      );
    in
    {
      options.my.attic = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "attic";
        };
        cacheName = lib.mkOption {
          type = lib.types.str;
          default = "atlas";
        };
        public = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        serverAlias = lib.mkOption {
          type = lib.types.str;
          default = "atlas-local";
        };
        autoPush = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          targetBasenames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "naboo"
              "nevarro"
              "emeraldecho"
            ];
          };
        };
      };

      options.my.host.services.attic = lib.mkEnableOption "Attic cache service";
      config = lib.mkIf config.my.host.services.attic (
        import ./_attic.nix (
          args
          // {
            inherit
              cacheEndpoint
              cfg
              clientConfigHome
              envSecretFile
              localApiEndpoint
              targetPattern
              ;
          }
        )
      );
    };
}
