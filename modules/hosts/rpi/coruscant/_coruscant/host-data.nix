{
  inputs,
  lib,
  ...
}:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib network; };
in
descriptorHelpers.mkRpiDescriptor {
  name = "Coruscant";
  outputName = "coruscant";
  hostName = "Coruscant";
  configuration = "Coruscant";
  network = {
    mode = "static";
    address = network.coruscant;
    localDnsRecords = [
      { hostname = "homeassistant"; }
    ];
  };
}
