{
  inputs,
  lib,
  ...
}:
let
  wsl = import ./_public.nix { inherit inputs lib; };
  descriptors = [
    (import ./nixos-wsl/_nixos-wsl/host-data.nix { inherit inputs lib; })
  ];
in
{
  imports = [ ./exports.nix ] ++ map wsl.mkRegisteredHost descriptors;
}
