{
  inputs,
  lib,
}:
rec {
  mkHostOutput =
    {
      buildAttrPath,
      collection,
      configuration,
      kind,
      name,
      system,
    }:
    {
      inherit
        buildAttrPath
        collection
        configuration
        kind
        name
        system
        ;
    };

  mkNixosOutput =
    {
      collection,
      configuration,
      name,
      system,
      buildProduct ? "toplevel",
    }:
    mkHostOutput {
      inherit
        collection
        configuration
        name
        system
        ;
      kind = "nixos";
      buildAttrPath = [
        "config"
        "system"
        "build"
        buildProduct
      ];
    };

  mkNixosOutputs =
    {
      collections ? [ "checks" ],
      configuration,
      name,
      system,
      buildProduct ? "toplevel",
    }:
    map (
      collection:
      mkNixosOutput {
        inherit
          collection
          configuration
          name
          system
          buildProduct
          ;
      }
    ) collections;

  mkHomeOutput =
    {
      collection,
      configuration,
      name,
      system,
      buildAttrPath ? [ "activationPackage" ],
    }:
    mkHostOutput {
      inherit
        buildAttrPath
        collection
        configuration
        name
        system
        ;
      kind = "home";
    };

  mkHomeOutputs =
    {
      collections ? [ "checks" ],
      configuration,
      name,
      system,
      buildAttrPath ? [ "activationPackage" ],
    }:
    map (
      collection:
      mkHomeOutput {
        inherit
          collection
          configuration
          name
          system
          buildAttrPath
          ;
      }
    ) collections;
}
