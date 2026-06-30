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
  name = "Ferrix";
  outputName = "ferrix";
  hostName = "Ferrix";
  address = network.ferrix;
  configuration = "Ferrix";
  nixosProfileNames = [ "sam-system-cli" ];
}
