{ ... }:
{
  flake.modules.nixos.bitwarden =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.bitwarden {
      home-manager.users.sam.home.packages = [ pkgs.bitwarden-desktop ];
      nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];
    };
}
