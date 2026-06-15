{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-work-private = {
    imports = [
      "${inputs.nix-work-secrets}/modules/sam-secrets-private.nix"
    ];
  };
}
