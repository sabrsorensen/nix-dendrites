{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-personal = {
    imports = with inputs.self.modules.homeManager; [
      gdrive
      mcp-personal
    ];

    my.gdrive.enable = true;
  };
}
