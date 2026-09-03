{ inputs, lib, ... }:
let
  read = file: lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/${file}");
  bootUuid = read "disk/kamino/boot-uuid.txt";
  rootFsUuid = read "disk/kamino/root-fs-uuid.txt";
  rootLuksUuid = read "luks/kamino/root.txt";
  swapLuksUuid = read "luks/kamino/swap.txt";
  swapUuid = read "disk/kamino/swap-uuid.txt";
in
{
  flake.modules.nixos.hardware-kamino =
    args@{ config, lib, ... }:
    lib.mkIf (config.my.host.name == "Kamino") (
      import ./_hardware.nix (
        args
        // {
          inherit
            bootUuid
            rootFsUuid
            rootLuksUuid
            swapLuksUuid
            swapUuid
            ;
        }
      )
    );
}
