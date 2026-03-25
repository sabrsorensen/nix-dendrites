{
  inputs,
  ...
}:
{
  flake.modules.nixos.ZaphodBeeblebrox = {
    imports = with inputs.self.modules.nixos; [
      system-desktop
      systemd-boot
      disko
      bluetooth
      nvidia
      xserver
      virtualisation
      threedprinter
      appimage
      deskflow
      flatpak
      kde
      minecraft
      steam
    ];
  };
  flake.modules.homeManager.ZaphodBeeblebrox = {
    imports = with inputs.self.modules.homeManager; [
    ];
  };
}
