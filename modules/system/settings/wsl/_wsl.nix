{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.wsl-base =
    {
      imports = [
        inputs.nixos-wsl.nixosModules.wsl
        ./_base-module.nix
        (import ./_certs-module.nix { inherit inputs lib; })
      ];
    };
}
