{
  lib,
  ...
}:
{
  flake.modules.nixos.secrets-context =
    {
      lib,
      ...
    }:
    {
      options.my.buildSecretRoot = lib.mkOption {
        type = lib.types.path;
        description = "Root path for build secrets";
      };
    };
}
