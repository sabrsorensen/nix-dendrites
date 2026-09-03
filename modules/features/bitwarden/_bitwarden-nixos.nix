{ ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    # Bitwarden Desktop currently depends on this Electron release.
    "electron-39.8.10"
  ];
}
