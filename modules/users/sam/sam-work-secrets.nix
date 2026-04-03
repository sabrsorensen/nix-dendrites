{
  lib,
  inputs,
  ...
}:
{
  flake.modules.homeManager."sam-work-secrets" = {
    my.buildSecretRoot = lib.mkForce inputs.nix-work-secrets;
    my.gitSecretRoot = lib.mkForce inputs.nix-work-secrets;
    my.gpgKeysDir = lib.mkForce "${inputs.nix-work-secrets}/gpg-keys";
  };
}
