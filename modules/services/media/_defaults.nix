{
  config,
  lib,
  ...
}:
{
  my.media = {
    configRoot = lib.mkDefault "/opt";
    podmanNetwork = lib.mkDefault "media";
  };
}
