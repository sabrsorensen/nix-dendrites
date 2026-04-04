{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    firefox
    vscode
    ../_steamdeck/steamdeck-home.nix
  ];
}
