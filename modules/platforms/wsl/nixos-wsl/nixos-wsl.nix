{ inputs, ... }:
{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/NixOS-WSL";
    inputs = {
      flake-compat.follows = "flake-compat";
      nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.nixos.nixos-wsl =
    args@{ config, lib, ... }:
    {
      # Broadcast like any platform module: NixOS-WSL gates all of its own
      # behaviour on wsl.enable (its only unconditional value, recovery.nix's
      # wsl.extraBin, is only consumed under wsl.enable), so importing its
      # option surface on every host is inert off-platform.
      imports = [ inputs.nixos-wsl.nixosModules.default ];
      config = lib.mkIf (config.my.host.platform == "wsl") (import ./_nixos-wsl.nix args);
    };
}
