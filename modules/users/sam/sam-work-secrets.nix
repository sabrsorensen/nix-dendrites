{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-secrets = {
    #my.buildSecretRoot = inputs.nix-secrets;
    #my.gitSecretRoot = inputs.nix-work-secrets;
    #my.gpgKeysDir = "${inputs.nix-work-secrets}/gpg-keys";
  };
}
