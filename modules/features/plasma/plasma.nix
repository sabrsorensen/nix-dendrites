{ inputs, lib, ... }:
{
  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  # The Home Manager half (plasma-manager settings) needs the input; the
  # NixOS half (the Plasma 6 session itself) does not.
  imports = lib.optional (inputs ? plasma-manager) ./_plasma.nix;

  flake.modules.nixos.plasma =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.plasma =
        lib.mkEnableOption "the KDE Plasma 6 desktop and its Plasma Manager user configuration";
      config = lib.mkIf config.my.host.features.plasma (import ./_plasma-nixos.nix args);
    };
}
