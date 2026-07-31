{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.dhcp-failover =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.dhcpCoredns.failover;
    in
    {
      options.my.dhcpCoredns.failover = {
        enable = lib.mkEnableOption "DHCP failover monitor";

        peerName = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Peer hostname for DHCP failover monitoring.";
        };

        peerIp = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Peer IP address for DHCP failover monitoring.";
        };

        probeDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Relative domain names that must resolve on the peer.";
        };
      };

      config = lib.mkIf (config.my.host.services.dhcpCoredns && cfg.enable) (
        import ./_content.nix (args // { inherit cfg domain; })
      );
    };
}
