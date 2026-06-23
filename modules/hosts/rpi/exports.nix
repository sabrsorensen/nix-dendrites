{
  inputs,
  lib,
  ...
}:
let
  moduleBuilders = import ./_module-builders.nix { inherit inputs lib; };
  mkServiceHostModule = import ./_rpi/service-host.nix { inherit inputs lib; };
  registrationBuilder = import ./_registration-builder.nix (
    {
      inherit inputs lib mkServiceHostModule;
    }
    // moduleBuilders
  );
in
{
  flake.lib.rpi = registrationBuilder;
  flake.modules.nixos.rpi-base = ./_rpi/base.nix;
}
