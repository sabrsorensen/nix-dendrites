{
  inputs,
  ...
}:
{
  # expansion of cli system for desktop use

  flake.modules.nixos.system-desktop = {
    imports = with inputs.self.modules.nixos; [
      system-cli
      printing
      plymouth
      wayland
      audio
      zsa
      cross-compile
      appimage
      deskflow
      threedprinter
      minecraft
      steam
    ];
  };

  flake.modules.homeManager.system-desktop = {
    imports = [
      inputs.self.modules.homeManager."graphical-home"
    ];
  };
}
