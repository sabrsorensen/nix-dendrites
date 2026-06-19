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
  flake.modules.homeManager.kaminoHostHome = import ./_kamino/home-manager.nix { inherit inputs; };

  flake.modules.nixos = {
    kamino = {
      imports = [
        ./_kamino/hardware.nix
        (import ./_kamino/filesystem.nix {
          inherit bootUuid rootFsUuid swapUuid;
        })
        ./_kamino/network.nix
        (import ./_kamino/boot.nix {
          inherit rootLuksUuid swapLuksUuid;
        })
        ./_kamino/desktop.nix
        ./_kamino/packages.nix
        ./_kamino/users/sam.nix
      ];
    };

    kaminoBootstrap = {
      imports = [
        ./_kamino/hardware.nix
        (import ./_kamino/filesystem.nix {
          inherit bootUuid rootFsUuid swapUuid;
        })
        ./_kamino/network.nix
        (import ./_kamino/boot.nix {
          inherit rootLuksUuid swapLuksUuid;
        })
        inputs.self.modules.nixos.systemd-boot
      ];
    };
  };
}
