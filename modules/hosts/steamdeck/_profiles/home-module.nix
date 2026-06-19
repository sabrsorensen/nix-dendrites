{ inputs, ... }:
{
  imports = with inputs.self.modules.homeManager; [
    steamdeck-home
  ];
}
