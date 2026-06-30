{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-personal = {
    imports = with inputs.self.modules.homeManager; [
      atuin
      gdrive
      mcp-personal
    ];

    my.gdrive.enable = true;
  };
}
