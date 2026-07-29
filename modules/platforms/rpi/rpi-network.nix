{ inputs, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
in
{
  flake.modules.nixos.rpi-network =
    { config, lib, ... }:
    let
      staticHosts = {
        Coruscant = {
          address = network.coruscant;
        };
        Ferrix = {
          address = network.ferrix;
        };
        Naboo = {
          address = network.naboo;
          nameservers = [
            network.nevarro
            "1.1.1.1"
            "9.9.9.9"
          ];
        };
        Nevarro = {
          address = network.nevarro;
          nameservers = [
            network.naboo
            "1.1.1.1"
            "9.9.9.9"
          ];
        };
      };
      host = staticHosts.${config.my.host.name} or null;
    in
    lib.mkIf (config.my.host.is.rpi && host != null) {
      my.host.address = host.address;
      networking = {
        useDHCP = false;
        defaultGateway = {
          address = network.gateway;
          interface = "end0";
        };
        nameservers = host.nameservers or [ ];
        interfaces.end0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = host.address;
              prefixLength = 24;
            }
          ];
        };
      };
    };
}
