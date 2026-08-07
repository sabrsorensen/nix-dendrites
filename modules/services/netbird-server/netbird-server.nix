{ inputs, lib, ... }:
let
  clientId = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/netbird/clientId.txt");
  domain = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/domain.txt");
in
{
  flake.modules.nixos.netbird-server =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      managementAddress = "127.0.0.1";
      managementPort = 33073;
      relayPort = 33080;
      netbirdDomain = "netbird.${domain}";
    in
    lib.mkIf config.my.host.services.netbirdServer (
      import ./_netbird-server.nix (
        args
        // {
          inherit
            inputs
            clientId
            domain
            managementAddress
            managementPort
            relayPort
            netbirdDomain
            ;
        }
      )
    );
}
