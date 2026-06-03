{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    firefox
    vscode
    ../_platform/steamdeck/steamdeck-home.nix
  ];
}
