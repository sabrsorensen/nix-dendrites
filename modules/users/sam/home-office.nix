{
  inputs,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager."sam-home-office" = {
    imports = [ hm.office ];
  };
}
