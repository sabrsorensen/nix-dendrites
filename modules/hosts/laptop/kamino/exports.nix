{
  inputs,
  lib,
  ...
}:
let
  bootUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/disk/kamino/boot-uuid.txt"
  );
  rootFsUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/disk/kamino/root-fs-uuid.txt"
  );
  rootLuksUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/luks/kamino/root.txt"
  );
  swapLuksUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/luks/kamino/swap.txt"
  );
  swapUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/disk/kamino/swap-uuid.txt"
  );
in
{
  flake.modules.nixos = {
    kamino = {
      imports = [
        ./_kamino/hardware.nix
        (
          { lib, ... }:
          import ./_kamino/filesystem.nix {
            inherit
              lib
              bootUuid
              rootFsUuid
              rootLuksUuid
              swapLuksUuid
              swapUuid
              ;
          }
        )
        ./_kamino/network.nix
        ./_kamino/users/sam.nix
      ];
    };
  };
}
