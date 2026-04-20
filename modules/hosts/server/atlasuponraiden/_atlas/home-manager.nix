{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    nix-index
  ];
}
