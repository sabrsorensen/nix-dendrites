{ config, inputs, ... }:
let
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
in
{
  flake.nixosConfigurations.ferrix = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      {
        networking.hostName = "Ferrix";

        my.host = {
          name = "Ferrix";
          formFactor = "server";
          home.enable = true;
          roles.rpi = true;
        };
      }
    ];
  };
}
