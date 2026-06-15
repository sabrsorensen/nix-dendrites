{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-graphical = {
    imports = [
      inputs.self.modules.homeManager."graphical-home"
    ];
  };
}
