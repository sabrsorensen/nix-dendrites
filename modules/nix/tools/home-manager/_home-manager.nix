{
  inputs,
  ...
}:
let
  home-manager-config =
    { lib, ... }:
    {
      home-manager = {
        verbose = true;
        useUserPackages = true;
        useGlobalPkgs = true;
        backupFileExtension = "backup";
        backupCommand = "rm";
        overwriteBackup = true;
      };
    };
in
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.modules.nixos.home-manager =
    { lib, options, ... }:
    let
      useDeterminateHomeManager =
        inputs ? determinate && lib.hasAttrByPath [ "determinateNix" ] options;
      homeManagerInput =
        if useDeterminateHomeManager then
          inputs."determinate-home-manager"
        else
          inputs.home-manager;
    in
    {
      imports = [
        homeManagerInput.nixosModules.home-manager
        home-manager-config
      ];

      config = lib.mkIf useDeterminateHomeManager {
        home-manager.sharedModules = [
          inputs.determinate.homeManagerModules.default
        ];
      };
    };
}
