{
  inputs,
  ...
}:
let
  inventory = import ./inventory.nix { inherit inputs; };
in
inventory
// import ./runtime.nix
// import ./variants.nix
