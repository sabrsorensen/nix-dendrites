{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "ZaphodBeeblebrox";
}
