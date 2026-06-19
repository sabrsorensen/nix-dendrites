{
  inputs,
  lib,
  ...
}:
let
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit lib; };
  host = import ./host.nix { inherit inputs; };
in
descriptorHelpers.mkSteamdeckDescriptor {
  name = "EmeraldEcho";
  identityFile = "~/.ssh/emeraldecho_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_emeraldecho_id_ed25519";
  hostName = host.hostName;
  config = host.config;
  homeOutputName = "home-deck-emeraldecho";
  platformHost = host;
  platformRegistration = import ./registration.nix { inherit inputs lib; };
}
