{
  inputs,
  lib,
  ...
}:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib network; };
in
descriptorHelpers.mkStaticDescriptor {
  name = "Coruscant";
  outputName = "coruscant";
  hostName = "Coruscant";
  address = network.coruscant;
  configuration = "Coruscant";
  nixosProfileNames = [ "sam-system-cli" ];
  localDnsRecords = [
    { hostname = "homeassistant"; }
  ];
}
