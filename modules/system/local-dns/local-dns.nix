{ inputs, lib, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  publisherOutputs = [
    "atlasuponraiden"
    "coruscant"
    "emeraldecho"
    "ferrix"
    "kamino"
    "nixpi"
    "zaphodbeeblebrox"
  ];
in
{
  flake.lib = import ./_content.nix { inherit inputs network publisherOutputs; };
}
