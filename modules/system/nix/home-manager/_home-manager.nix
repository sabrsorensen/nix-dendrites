{ inputs, ... }:
{
  flake.modules.nixos.home-manager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      backupCommand = "rm";
      overwriteBackup = true;
      extraSpecialArgs = { inherit inputs; };
    };
  };
}
