{
  inputs,
  lib,
  ...
}:
let
  server = import ./_registration-builder.nix { inherit inputs lib; };
  descriptors = [
    (import ./atlasuponraiden/_atlas/host-data.nix { inherit inputs lib; })
  ];
in
{
  imports = [ ./exports.nix ] ++ map server.mkRegisteredHost descriptors;
}
