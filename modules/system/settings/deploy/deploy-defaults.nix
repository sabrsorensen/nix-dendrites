{
  inputs,
  ...
}:
let
  nixos = inputs.self.modules.nixos;
in
{
  flake.modules.nixos.deploy-defaults =
    { ... }:
    {
      imports = [
        nixos."deploy-builder-defaults"
        nixos."deploy-local-defaults"
      ];
    };
}
