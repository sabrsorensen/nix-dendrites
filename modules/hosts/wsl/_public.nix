{
  inputs,
  lib,
  ...
}:
import ./_registration-builder.nix { inherit inputs lib; }
