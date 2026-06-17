{
  inputs,
  lib,
  ...
}:
let
  server = import ./_public.nix { inherit inputs lib; };
  descriptors = [
    (import ./atlasuponraiden/_atlas/host-data.nix { inherit inputs lib; })
  ];
in
{
  imports = [ ./exports.nix ] ++ map server.mkRegisteredHost descriptors;
}
