{
  inputs,
  lib,
  ...
}:
let
  moduleBuilders = import ../_module-builders.nix { inherit inputs lib; };
  mkServiceHostModule = import ../_rpi/service-host.nix { inherit inputs lib; };
  registrationBuilder = import ../_registration-builder-old.nix (
    {
      inherit inputs lib mkServiceHostModule;
    }
    // moduleBuilders
  );
in
{
  flake.lib.rpi-old = registrationBuilder;
  flake.modules.nixos.rpi-base-old = ../_rpi/base.nix;
}
