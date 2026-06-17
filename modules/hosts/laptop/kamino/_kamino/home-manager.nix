{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    firefox
    gdrive
    konsole
    mcp
    mcp-personal
    nix-index
    vscode
  ];

  my.gdrive.enable = true;
}
