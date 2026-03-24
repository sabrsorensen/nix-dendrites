{
  inputs,
  ...
}:
{
  flake.modules.nixos.determinate = {
    imports = [
      inputs.determinate.nixosModules.default
    ];
    nix.enable = false; # Determinate Nix handles the Nix configuration
  };
}
