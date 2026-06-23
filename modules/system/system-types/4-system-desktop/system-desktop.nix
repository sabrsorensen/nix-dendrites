{
  inputs,
  lib,
  ...
}:
{
  # expansion of cli system for shared desktop/session foundations

  flake.modules.nixos.system-desktop = {
    imports = with inputs.self.modules.nixos; [
      system-cli
      printing
      plymouth
      wayland
      audio
      appimage
      kde
      xserver
    ];

    my.services.printing.enable = lib.mkDefault true;
  };

  flake.modules.homeManager.system-desktop = {
    imports = [ inputs.self.modules.homeManager."graphical-home" ];
  };
}
