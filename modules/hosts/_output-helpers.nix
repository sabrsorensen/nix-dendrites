{
  inputs,
  lib,
}:
{
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
    {
      collection,
      descriptors,
      resolveDescriptor,
      system,
    }:
    lib.listToAttrs (
      map
        (descriptor: {
          name = descriptor.name;
          value = resolveDescriptor descriptor;
        })
        (
          builtins.filter (
            descriptor: descriptor.collection == collection && descriptor.system == system
          ) descriptors
        )
    );
}
