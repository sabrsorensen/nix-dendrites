{
  inputs,
  lib,
  ...
}:
let
  platformHelpers = import ./_platform-helpers.nix { inherit inputs; };
  registrationBuilder = import ./_registration-builder.nix {
    inherit lib;
    inherit (platformHelpers) steamdeck;
  };
in
{ inherit (platformHelpers) steamdeck; } // registrationBuilder
