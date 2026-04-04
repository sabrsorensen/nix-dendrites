{ inputs, ... }:
{
  imports = [ inputs.self.modules.homeManager."wsl-home" ];
}
