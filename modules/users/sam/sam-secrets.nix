{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-secrets = {
    my.buildSecretRoot = inputs.nix-secrets;
    my.gitSecretRoot = inputs.nix-secrets;
    my.gpgKeysDir = "${inputs.nix-secrets}/gpg-keys";
  };
}
