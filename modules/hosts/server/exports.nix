{
  inputs,
  lib,
  ...
}:
let
  server = import ./_registration-builder.nix { inherit inputs lib; };
in
{
  flake.lib.server = server;
}
