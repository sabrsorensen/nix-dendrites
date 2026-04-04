{
  inputs,
  lib,
  ...
}:
let
  luksUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/luks/kamino.txt");
in
{
  flake.modules.nixos.Kamino =
    {
      imports = with inputs.self.modules.nixos; [
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
        nvidia
        kde
        wine
        xserver
      ];

      home-manager.users.sam.imports = [
        inputs.self.modules.homeManager.Kamino
      ];
    };

  flake.modules.homeManager.Kamino = import ./_kamino/home-manager.nix { inherit inputs; };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "Kamino";
}
