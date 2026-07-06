{
  inputs,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager.sam-home-media = {
    imports = with hm; [
      beets
      demlo
    ];
  };
}
