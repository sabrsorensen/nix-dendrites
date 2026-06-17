{ inputs, ... }:
with inputs.self.modules.homeManager;
[
  beets
  nix-index
  demlo
]
