{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.my.media.enable {
    my.media = {
      configRoot = lib.mkDefault "/opt";
      podmanNetwork = lib.mkDefault "media";
    };
  };
}
