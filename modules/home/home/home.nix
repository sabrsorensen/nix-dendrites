{ inputs, ... }:
{
  imports = [ (import ./_content.nix { inherit inputs; }) ];
}
