{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    beets
    nix-index
    demlo
  ];
}
