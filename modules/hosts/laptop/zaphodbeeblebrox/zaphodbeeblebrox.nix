{
  inputs,
  ...
}:
{
  flake.modules.nixos.ZaphodBeeblebrox = {
    imports = with inputs.self.modules.nixos; [
      sam
      ./_zaphod/hardware.nix
      ./_zaphod/filesystem.nix
      ./_zaphod/network.nix
      ./_zaphod/users/sam.nix
      system-desktop
      systemd-boot
      disko
      bluetooth
      nvidia
      xserver
      virtualisation
      kde
      appimage
      deskflow
      flatpak
      threedprinter
      minecraft
      steam
    ];
  };
  flake.modules.homeManager.ZaphodBeeblebrox = {
    imports = with inputs.self.modules.homeManager; [
    ];
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "ZaphodBeeblebrox";
}
