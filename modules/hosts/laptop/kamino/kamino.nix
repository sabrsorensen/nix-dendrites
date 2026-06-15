{
  inputs,
  lib,
  ...
}:
let
  primaryInteractiveUser = "sam";
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
  mkWorkstation = import ../_base/workstation.nix;
in
mkWorkstation {
  inherit inputs;
  inherit lib;
  systemName = "Kamino";
  homeModule = import ./_kamino/home-manager.nix { inherit inputs; };
  extraImports = with inputs.self.modules.nixos; [
    sam
    ./_kamino/hardware.nix
    (import ./_kamino/filesystem.nix {
      inherit
        bootUuid
        rootFsUuid
        swapUuid
        ;
    })
    ./_kamino/network.nix
    (import ./_kamino/boot.nix {
      inherit
        rootLuksUuid
        swapLuksUuid
        ;
    })
    ./_kamino/desktop.nix
    ./_kamino/packages.nix
    ./_kamino/users/sam.nix
    system-desktop
    systemd-boot
    flatpak
    nix-index
    nvidia
    kde
    wine
    xserver
  ];
  extraHostConfig = {
    my.host.primaryInteractiveUser = primaryInteractiveUser;

    home-manager.users.sam.imports = [
      inputs.self.modules.homeManager.Kamino
    ];
  };
  primaryInteractiveUser = primaryInteractiveUser;
  sshIdentityFile = "~/.ssh/kamino_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_kamino_id_ed25519";
}
