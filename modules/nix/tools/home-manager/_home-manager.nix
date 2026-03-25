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
    { lib, ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        home-manager-config
      ];
    };
}
