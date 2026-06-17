{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-private = {
    imports = [
      inputs.self.modules.homeManager.sam-syncthing
    ];
  };
}
