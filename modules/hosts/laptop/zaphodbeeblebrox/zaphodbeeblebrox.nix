{
  inputs,
  lib,
  ...
}:
let
  primaryInteractiveUser = "sam";
  rootLuksUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/luks/zaphod/root.txt"
  );
  mkWorkstation = import ../_base/workstation.nix;
in
mkWorkstation {
  inherit inputs;
  inherit lib;
  systemName = "ZaphodBeeblebrox";
  homeModule = {
    imports = with inputs.self.modules.homeManager; [
      firefox
      konsole
      mcp
      mcp-personal
      nix-index
      vscode
    ];
  };
  extraImports = with inputs.self.modules.nixos; [
    sam
    ./_zaphod/hardware.nix
    ({ lib, ... }: import ./_zaphod/filesystem.nix { inherit lib rootLuksUuid; })
    ./_zaphod/network.nix
    ./_zaphod/users/sam.nix
    system-desktop
    systemd-boot
    disko
    bluetooth
    flatpak
    nix-index
    kde
    nvidia
    wine
    xserver
  ];
  extraHostConfig = {
    my.host.primaryInteractiveUser = primaryInteractiveUser;

    home-manager.users.sam = {
      imports = [
        inputs.self.modules.homeManager.ZaphodBeeblebrox
      ];
    };
  };
  primaryInteractiveUser = primaryInteractiveUser;
  sshIdentityFile = "~/.ssh/zaphod_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_zaphodbeeblebrox_id_ed25519";
}
