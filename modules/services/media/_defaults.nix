{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.my.services.media.enable {
    my.services.media = {
      configRoot = lib.mkDefault "/opt";
      podmanNetwork = lib.mkDefault "media";
    };
  };
}
