{
  inputs,
  lib,
  ...
}:
let
  laptop = import ./_public.nix { inherit inputs lib; };
  descriptors = [
    (import ./kamino/_kamino/host-data.nix { inherit inputs lib; })
    (import ./zaphodbeeblebrox/_zaphod/host-data.nix { inherit inputs lib; })
  ];
in
{
  imports = [ ./exports.nix ] ++ map laptop.mkRegisteredHost descriptors;
}
