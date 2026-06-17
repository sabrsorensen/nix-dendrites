{
  inputs,
  lib,
  ...
}:
let
  outputConstructors = import ./_output-constructors.nix { inherit inputs lib; };
  inventoryConstructors = import ./_inventory-constructors.nix { inherit lib; };
  configurationConstructors = import ./_configuration-constructors.nix { inherit inputs lib; };
in
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib =
    {
      hostInventory = { };
      localDns = { };
    }
    // outputConstructors
    // inventoryConstructors
    // configurationConstructors;
}
