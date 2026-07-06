{
  inputs,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
  nixos = inputs.self.modules.nixos;
in
{
  # expansion of default system with basic system settings & cli-tools

  flake.modules.nixos.system-cli = {
    imports = with nixos; [ system-default ];
  };

  flake.modules.homeManager.system-cli = {
    imports = with hm; [
      home
    ];
  };
}
