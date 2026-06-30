{
  inputs,
  ...
}:
{
  flake.modules.homeManager."graphical-home" = {
    imports = with inputs.self.modules.homeManager; [
      home
      browser
      konsole
    ];
  };
}
