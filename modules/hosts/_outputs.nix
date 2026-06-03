{
  inputs,
  config,
  lib,
  ...
}:
{
  perSystem =
    { system, ... }:
    let
      hosts = config.flake.lib.hostInventory or { };
      descriptors = lib.concatMap (host: host.outputs or [ ]) (builtins.attrValues hosts);
      resolveDescriptor =
        descriptor:
        let
          outputSet =
            if descriptor.kind == "home" then
              inputs.self.homeConfigurations.${descriptor.configuration}
            else
              inputs.self.nixosConfigurations.${descriptor.configuration};
        in
        lib.getAttrFromPath descriptor.buildAttrPath outputSet;
      outputAttrsFor =
        collection:
        lib.listToAttrs (
          map
            (descriptor: {
              name = descriptor.name;
              value = resolveDescriptor descriptor;
            })
            (builtins.filter (
              descriptor: descriptor.collection == collection && descriptor.system == system
            ) descriptors)
        );
    in
    {
      checks = outputAttrsFor "checks";
      packages = outputAttrsFor "packages";
    };
}
