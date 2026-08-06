{ config, inputs, ... }:
{
  imports = [
    (import ./_content.nix {
      inherit inputs;
      homeModules = config.dendritic.homeManagerModules;
    })
  ];
}
