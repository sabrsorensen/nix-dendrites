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
      bitwarden
      flatpak
    ];
  };

  flake.modules.homeManager.system-workstation = {
    imports = with hm; [
      system-desktop
      bitwarden
      office
    ];
  };
}
