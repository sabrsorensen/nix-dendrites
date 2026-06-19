{
  inputs,
  ...
}:
{
  # expansion of cli system for desktop use

  flake.modules.nixos.system-desktop = {
    nixpkgs.config.permittedInsecurePackages = [
      # Bitwarden Desktop currently depends on this Electron release.
      "electron-39.8.10"
    ];

    imports = with inputs.self.modules.nixos; [
      system-cli
      printing
      plymouth
      wayland
      audio
      zsa
      cross-compile
      appimage
      bluetooth
      deskflow
      flatpak
      kde
      threedprinter
      minecraft
      nvidia
      wine
      xserver
    ];
  };

  flake.modules.homeManager.system-desktop = {
    imports = with inputs.self.modules.homeManager; [
      "graphical-home"
    ];
  };
}
