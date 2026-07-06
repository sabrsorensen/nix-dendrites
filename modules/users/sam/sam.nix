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
        hm.bitwarden
        hm."graphical-home"
        hm."sam-home-communications"
        hm."sam-home-media-clients"
        hm."sam-home-device-tools"
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
