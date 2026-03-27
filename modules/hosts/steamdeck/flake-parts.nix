{
  ...
}:
{
  flake-file.inputs = {
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    decky-packages = {
      url = "path:./steamdeck-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
