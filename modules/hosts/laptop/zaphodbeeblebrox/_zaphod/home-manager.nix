{ inputs, ... }:
{
  imports = [
    inputs.self.modules.homeManager."sam-home-personal"
  ];
}
