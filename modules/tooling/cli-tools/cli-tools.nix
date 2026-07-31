{ inputs, ... }:
{
  flake-file.inputs.nix-auto-follow = {
    url = "github:fzakaria/nix-auto-follow";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.cli-tools =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    import ./_content.nix (args // { inherit inputs; });
}
