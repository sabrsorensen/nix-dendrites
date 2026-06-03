{
  inputs,
  lib,
  ...
}:
let
  luksUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/luks/kamino.txt");
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
    ./_kamino/filesystem.nix
    ./_kamino/network.nix
    (import ./_kamino/boot.nix { inherit luksUuid; })
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
    home-manager.users.sam.imports = [
      inputs.self.modules.homeManager.Kamino
    ];
  };
  sshIdentityFile = "~/.ssh/kamino_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_kamino_id_ed25519";
}
