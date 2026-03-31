{
  inputs,
  ...
}:
{
  flake.modules.nixos.system-secrets = {
    my.buildSecretRoot = inputs.nix-secrets;
  };
}
