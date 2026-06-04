{
  inputs,
  ...
}:
{
  flake.modules.nixos.sam-system-private = {
    imports = [
      "${inputs.nix-secrets}/modules/system-secrets-private.nix"
    ];
  };
}
