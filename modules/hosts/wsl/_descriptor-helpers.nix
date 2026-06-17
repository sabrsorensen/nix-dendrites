{
  inputs,
  lib,
  ...
}:
let
  x86Helpers = import ../_x86-descriptor-helpers.nix { inherit inputs lib; };
in
{
  mkWslDescriptor =
    {
      name,
      outputName,
      homeImports,
      hostModule,
      extraImports ? [ ],
      config ? { },
    }:
    x86Helpers.mkX86Descriptor {
      inherit
        name
        config
        homeImports
        ;
      nixosImports = [
        hostModule
      ]
      ++ extraImports;
      inventory = x86Helpers.mkX86Inventory {
        inherit name outputName;
      };
    };
}
