{
  inputs,
  ...
}:
let
  home-manager-config =
    { config, lib, ... }:
    {
      home-manager = {
        verbose = true;
        useUserPackages = true;
        useGlobalPkgs = true;
        extraSpecialArgs.inventory = inputs.self.lib.shared.mkHomeManagerInventory inputs.self.lib.hostInventory;
        sharedModules = [
          {
            my.host = {
              inherit (config.my.host)
                name
                domain
                formFactor
                primaryInteractiveUser
                roles
                syncthing
                features
                ssh
                tags
                ;
              lifecycle.mode = config.my.host.lifecycle.mode;
              deploy = {
                inherit (config.my.host.deploy)
                  canDeployRemotely
                  sleepy
                  localUser
                  repoName
                  localFlakePath
                  ;
              };
            };
          }
        ];
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
