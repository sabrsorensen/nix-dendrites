{
  inputs,
  lib,
  ...
}:
let
  moduleBuilders = import ./_module-builders.nix { inherit inputs lib; };
  mkServiceHostModule = import ./_rpi/service-host.nix { inherit inputs lib; };
  rpi = import ./_registration-builder.nix (
    {
      inherit inputs lib mkServiceHostModule;
    }
    // moduleBuilders
  );
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
