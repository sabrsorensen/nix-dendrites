{
  inputs,
  lib,
  ...
}:
let
  rootLuksUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/luks/zaphod/root.txt"
  );
in
{
  flake.modules.homeManager.zaphodBeeblebroxHostHome = import ./_zaphod/home-manager.nix {
    inherit inputs;
  };

  flake.modules.nixos = {
    zaphodBeeblebrox = {
      imports = [
        ./_zaphod/hardware.nix
        (
          { lib, ... }:
          import ./_zaphod/filesystem.nix {
            inherit lib rootLuksUuid;
          }
        )
        ./_zaphod/network.nix
        ./_zaphod/users/sam.nix
      ];
    };
  };
}
