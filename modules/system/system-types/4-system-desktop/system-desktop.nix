{
  inputs,
  lib,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
  nixos = inputs.self.modules.nixos;
in
{
  # expansion of cli system for shared desktop/session foundations

  flake.modules.nixos.system-desktop = {
    imports = with nixos; [ system-cli ];
  };

  flake.modules.homeManager.system-desktop = {
    imports = [ hm."graphical-home" ];
  };
}
