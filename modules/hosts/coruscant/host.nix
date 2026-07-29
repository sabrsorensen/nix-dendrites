{ config, inputs, ... }:
let
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
in
{
  flake.nixosConfigurations.coruscant = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      {
        networking.hostName = "Coruscant";

        my.host = {
          name = "Coruscant";
          formFactor = "server";
          platform = "rpi";
          home.enable = true;
        };
        my.localDns.records = [ { hostname = "homeassistant"; } ];
      }
    ];
  };
}
