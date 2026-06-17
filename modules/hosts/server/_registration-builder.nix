{
  inputs,
  lib,
}:
rec {
  mkServerModule =
    descriptor:
    { config, ... }:
    {
      imports = descriptor.nixos.imports;

      my.host = descriptor.config;
      my.localDns.records = descriptor.localDnsRecords or [ ];

      services.openssh.allowSFTP = true;
      nix.settings.system-features = config.systemConstants.atlas.systemFeatures;

      home-manager.users.${descriptor.user.name} = {
        imports = [
          inputs.self.modules.homeManager.${descriptor.name}
        ];
        my.syncthing.enable = lib.mkForce false;
      };
    };

  mkRegisteredHost =
    descriptor:
    {
      flake.modules.nixos.${descriptor.name} = mkServerModule descriptor;

      flake.modules.homeManager.${descriptor.name} = {
        imports = descriptor.home.imports;
      };

      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" descriptor.name;
    };
}
