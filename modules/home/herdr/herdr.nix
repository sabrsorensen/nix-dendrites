{ inputs, ... }:
{
  # Herdr's Nix flake exposes its release build as the default package.
  # Keep the input next to the Home Manager module that consumes it.
  flake-file.inputs.herdr = {
    url = "github:herdrdev/herdr/v0.7.5";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.home-herdr =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) (
      import ./_content.nix (args // { inherit inputs; })
    );
}
