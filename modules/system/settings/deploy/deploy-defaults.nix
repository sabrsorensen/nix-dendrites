{
  inputs,
  ...
}:
{
  flake.modules.nixos.deploy-defaults =
    { ... }:
    {
      imports = [
        inputs.self.modules.nixos."deploy-builder-defaults"
        inputs.self.modules.nixos."deploy-local-defaults"
      ];
    };
}
