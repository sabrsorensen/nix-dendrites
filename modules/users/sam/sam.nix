{
  inputs,
  lib,
  ...
}:

let
  hm = inputs.self.modules.homeManager;
  username = "sam";
  userHelpers = import ../_module-helpers.nix { inherit inputs lib; };
in
userHelpers.mkUserFamily {
  inherit username;
  homeConfigurationSystem = "x86_64-linux";
  variants = [
    {
      homeImports = [
        hm.sam-home-base
        hm."graphical-home"
      ];
      extraUserConfig.extraGroups = [
        "wheel"
        "podman"
      ];
    }

    {
      systemModuleName = "sam-system-cli";
      homeModuleName = "sam-home-cli";
      homeImports = with hm; [
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
