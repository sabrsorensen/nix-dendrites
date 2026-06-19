{
  inputs,
  lib,
  ...
}:
let
  rpi = import ./_public.nix { inherit inputs lib; };
  descriptors = [
    (import ./coruscant/_coruscant/host-data.nix { inherit inputs lib; })
    (import ./ferrix/_ferrix/host-data.nix { inherit inputs lib; })
    (import ./naboo/_naboo/host-data.nix { inherit inputs lib; })
    (import ./nevarro/_nevarro/host-data.nix { inherit inputs lib; })
    (import ./nixpi/_nixpi/host-data.nix { inherit inputs lib; })
  ];
in
{
  imports = [ ./exports.nix ] ++ map rpi.mkRegisteredHost descriptors;
}
