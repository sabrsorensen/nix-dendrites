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
    { config, lib, ... }:
    {
      imports = [ inputs.nixos-wsl.nixosModules.default ];
      config = lib.mkIf (config.my.host.platform == "wsl") (import ./_nixos-wsl.nix);
    };
}
