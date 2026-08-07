{ config, inputs, ... }:
{
  flake.nixosConfigurations."nixos-wsl" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      (import ./_host.nix)
    ];
  };
}
