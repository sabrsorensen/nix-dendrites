{
  flake.modules.nixos.bitwarden = {
    nixpkgs.config.permittedInsecurePackages = [
      # Bitwarden Desktop currently depends on this Electron release.
      "electron-39.8.10"
    ];
  };

  flake.modules.homeManager.bitwarden =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bitwarden-desktop ];
    };
}
