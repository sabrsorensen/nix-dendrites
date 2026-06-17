{
  inputs,
  config,
  lib,
  ...
}:
let
  outputHelpers = import ./_output-helpers.nix { inherit inputs lib; };
in
{
  perSystem =
    { system, ... }:
    let
      hosts = config.flake.lib.hostInventory or { };
      descriptors = lib.concatMap (host: host.outputs or [ ]) (builtins.attrValues hosts);
    in
    {
      checks = outputHelpers.outputAttrsFor {
        collection = "checks";
        inherit descriptors system;
        inherit (outputHelpers) resolveDescriptor;
      };
      packages = outputHelpers.outputAttrsFor {
        collection = "packages";
        inherit descriptors system;
        inherit (outputHelpers) resolveDescriptor;
      };
    };
}
