{
  inputs,
  lib,
  ...
}:

let
  username = "sam";
  userHelpers = import ../_module-helpers.nix { inherit inputs lib; };
in
userHelpers.mkUserFamily {
  inherit username;
  homeConfigurationSystem = "x86_64-linux";
  variants = [
    {
      homeImports = with inputs.self.modules.homeManager; [
        sam-home-base
        sam-home-desktop
      ];
      extraUserConfig.extraGroups = [
        "wheel"
        "podman"
      ];
    }

    {
      systemModuleName = "sam-system-cli";
      homeModuleName = "sam-home-cli";
      homeImports = with inputs.self.modules.homeManager; [
        home
        sam-home-base
      ];
      extraUserConfig.extraGroups = [
        "media"
        "podman"
        "wheel"
      ];
    }
  ];
}
