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
        sam-home-graphical
        sam-home-private
      ];
      extraSystemImports = with inputs.self.modules.nixos; [ podman ];
      extraUserConfig.extraGroups = [ "wheel" "podman" ];
    }

    {
      systemModuleName = "samCli";
      homeModuleName = "samCli";
      homeImports = with inputs.self.modules.homeManager; [
        home
        sam-home-base
        sam-home-private
      ];
      extraUserConfig.extraGroups = [
        "media"
        "podman"
        "wheel"
      ];
      extraSystemConfig.programs.fish.enable = true;
    }
  ];
}
