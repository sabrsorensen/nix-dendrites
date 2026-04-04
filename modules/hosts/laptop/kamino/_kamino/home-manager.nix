{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    firefox
    konsole
    mcp
    mcp-personal
    vscode
  ];
}
