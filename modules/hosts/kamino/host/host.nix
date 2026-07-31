{ config, inputs, ... }:
{
  flake.nixosConfigurations.kamino = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      (import ./_content.nix { inherit inputs; })
    ];
  };
}
