{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  imports = [ ./_outputs.nix ];
}
