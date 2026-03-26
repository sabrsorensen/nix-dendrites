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
      options.my.buildSecretRoot = lib.mkOption {
        type = lib.types.path;
        description = "Root path for build secrets";
      };
      options.my.gitSecretRoot = lib.mkOption {
        type = lib.types.path;
        description = "Root path for git identity data";
      };
      options.my.gpgKeysDir = lib.mkOption {
        type = lib.types.path;
        description = "Root path for gpg keys";
      };
    };
}
