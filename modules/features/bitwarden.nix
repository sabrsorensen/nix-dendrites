{ ... }:
{
  flake.modules.nixos.bitwarden =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.features.bitwarden && config.my.host.home.enable) {
      nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];
      home-manager.users.sam.home.packages = [ pkgs.bitwarden-desktop ];
    };
}
