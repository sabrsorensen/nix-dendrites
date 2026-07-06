{
  inputs,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager."graphical-home" = {
    imports = with hm; [
      home
      browser
      firefox
      konsole
    ];
  };
}
