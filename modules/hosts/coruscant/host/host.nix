{ config, inputs, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  rpiHardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
in
{
  flake.nixosConfigurations.coruscant = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      rpiHardware
      (import ./_host.nix { inherit network; })
    ];
  };
}
