{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    firefox
    vscode
    steamdeck-home
  ];
}
