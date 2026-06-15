{ inputs, ... }:
{
  imports = [
    inputs.self.modules.homeManager."work-home"
    inputs.self.modules.homeManager."wsl-home"
  ];
}
