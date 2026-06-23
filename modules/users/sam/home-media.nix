{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-media = {
    imports = with inputs.self.modules.homeManager; [
      beets
      demlo
    ];
  };
}
