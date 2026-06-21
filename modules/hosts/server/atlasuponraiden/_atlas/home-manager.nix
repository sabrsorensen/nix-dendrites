{ inputs, ... }:
with inputs.self.modules.homeManager;
{
  imports = [
    atuin
    beets
    gdrive
    demlo
  ];

  my.gdrive.enable = true;
}
