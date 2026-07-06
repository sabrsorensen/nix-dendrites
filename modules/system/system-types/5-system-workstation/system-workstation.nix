{
  inputs,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
  nixos = inputs.self.modules.nixos;
in
{
  flake.modules.nixos.system-workstation = {
    imports = with nixos; [
      system-desktop
      flatpak
    ];
  };

  flake.modules.homeManager.system-workstation = {
    imports = [ hm.system-desktop ];
  };
}
