{
  inputs,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager.sam-home-personal = {
    imports = with hm; [
      atuin
      gdrive
      mcp-personal
    ];

    my.gdrive.enable = true;
  };
}
