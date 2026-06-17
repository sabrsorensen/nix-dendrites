{ inputs, ... }:
with inputs.self.modules.homeManager;
[
  beets
  gdrive
  nix-index
  demlo
  { my.gdrive.enable = true; }
]
