# modules/home/example/example.nix
{ inputs, ... }:
{
  flake-file.inputs.example = {
    url = "github:example/example/v1.2.3";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.home-example =
    args@{
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
    in
    {
      config = lib.mkIf (host.home.enable && host.features.example) (
        import ./_content.nix (args // { inherit inputs; })
      );
    };
}

# modules/home/example/_content.nix
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  username = config.my.host.home.username;
  examplePackage = inputs.example.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home-manager.users.${username}.home.packages = [ examplePackage ];
}
