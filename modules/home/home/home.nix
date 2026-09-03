{ config, inputs, ... }:
{
  imports = [
    (import ./_home.nix {
      inherit inputs;
      homeModules = config.dendritic.homeManagerModules;
    })
  ];
}
