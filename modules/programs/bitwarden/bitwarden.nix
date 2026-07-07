{
  flake.modules.nixos.bitwarden =
    { lib, config, ... }:
    let
      enabled = lib.attrByPath [ "my" "host" "features" "bitwarden" ] false config;
    in
    lib.mkIf enabled {
      nixpkgs.config.permittedInsecurePackages = [
        # Bitwarden Desktop currently depends on this Electron release.
        "electron-39.8.10"
      ];
    };

  flake.modules.homeManager.bitwarden =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      enabled = lib.attrByPath [ "my" "host" "features" "bitwarden" ] false config;
    in
    lib.mkIf enabled {
      home.packages = [ pkgs.bitwarden-desktop ];
    };
}
