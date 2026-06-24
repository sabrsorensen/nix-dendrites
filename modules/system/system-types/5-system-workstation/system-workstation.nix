{
  inputs,
  ...
}:
{
  flake.modules.nixos.system-workstation = {
    nixpkgs.config.permittedInsecurePackages = [
      # Bitwarden Desktop currently depends on this Electron release.
      "electron-39.8.10"
    ];

    imports = with inputs.self.modules.nixos; [
      system-desktop
      podman
      zsa
      cross-compile
      bluetooth
      deskflow
      flatpak
      threedprinter
      minecraft
      steam
      nvidia
      wine
    ];
  };

  flake.modules.homeManager.system-workstation = {
    imports = [ inputs.self.modules.homeManager.system-desktop ];
  };
}
