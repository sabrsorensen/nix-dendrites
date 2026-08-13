{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
in
{
  flake.modules.nixos.blocky =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.blocky;
      networkConfig = network;
      localDomain = domain;
    in
    {
      options.my.blocky = {
        enable = lib.mkEnableOption "Blocky DNS service";

        prometheus = {
          enable = lib.mkEnableOption "Prometheus metrics endpoint for Blocky";

          httpPort = lib.mkOption {
            type = lib.types.port;
            default = 4000;
            description = "HTTP port used by Blocky for Prometheus metrics.";
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "/metrics";
            description = "HTTP path used by Blocky to expose Prometheus metrics.";
          };
        };
      };

      options.my.host.services.blocky = lib.mkEnableOption "Blocky DNS service";
      config = lib.mkIf config.my.host.services.blocky (
        import ./_blocky.nix (args // { inherit cfg networkConfig localDomain; })
      );
    };
}
