{ config, inputs, ... }:
let
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
  payload = import ./_host.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.nixpi = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      payload.hostModule
    ];
  };
  flake.nixosConfigurations."nixpi-image" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      payload.hostModule
      payload.imageModule
    ];
  };
  flake.nixosConfigurations."nixpi-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      payload.bootstrapModule
    ];
  };
  flake.nixosConfigurations."nixpi-bootstrap-image" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      payload.bootstrapModule
      payload.bootstrapImageModule
    ];
  };
}
