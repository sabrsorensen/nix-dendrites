{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-home-private = {
    imports = [
      "${inputs.nix-secrets}/modules/sam-syncthing-universal.nix"
      "${inputs.nix-secrets}/modules/sam-secrets-private.nix"
    ];
  };
}
