{ config, inputs, ... }:
{
  flake.nixosConfigurations.zaphodbeeblebrox = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      (import ./_host.nix { inherit inputs; })
    ];
  };
}
