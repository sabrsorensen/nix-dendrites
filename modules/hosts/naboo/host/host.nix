{ config, inputs, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
  payload = import ./_host.nix { inherit inputs network; };
in
{
  flake.nixosConfigurations.naboo = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      payload.hostModule
    ];
  };
  flake.nixosConfigurations."naboo-image" = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      payload.hostModule
      payload.imageModule
    ];
  };
}
