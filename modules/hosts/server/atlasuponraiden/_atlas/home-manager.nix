{ inputs, ... }:
with inputs.self.modules.homeManager;
{
  imports = [
    beets
    gdrive
    demlo
  ];

  my.gdrive.enable = true;
}
