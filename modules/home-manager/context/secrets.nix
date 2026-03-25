{
  lib,
  ...
}:
{
  flake.modules.homeManager.secrets-context =
    {
      lib,
      ...
    }:
    {
      options.my.gitSecretRoot = lib.mkOption {
        type = lib.types.path;
        description = "Root path for git identity data";
      };
    };
}
