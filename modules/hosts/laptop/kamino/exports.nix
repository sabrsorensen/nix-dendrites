{
  inputs,
  lib,
  ...
}:
let
  bootUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/disk/kamino/boot-uuid.txt");
  rootFsUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/disk/kamino/root-fs-uuid.txt");
  rootLuksUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/luks/kamino/root.txt");
  swapLuksUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/luks/kamino/swap.txt");
  swapUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/disk/kamino/swap-uuid.txt");
in
{
  flake.modules = {
    homeManager.kaminoHome = import ./_kamino/home-manager.nix { inherit inputs; };

    nixos = {
      kaminoHardware = ./_kamino/hardware.nix;
      kaminoFilesystem = import ./_kamino/filesystem.nix {
        inherit bootUuid rootFsUuid swapUuid;
      };
      kaminoNetwork = ./_kamino/network.nix;
      kaminoBoot = import ./_kamino/boot.nix {
        inherit rootLuksUuid swapLuksUuid;
      };
      kaminoDesktop = ./_kamino/desktop.nix;
      kaminoPackages = ./_kamino/packages.nix;
      kaminoUserSam = ./_kamino/users/sam.nix;
    };
  };
}
