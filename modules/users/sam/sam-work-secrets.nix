{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-secrets = {
    #my.gitSecretRoot = inputs.nix-work-secrets;
  };
}
