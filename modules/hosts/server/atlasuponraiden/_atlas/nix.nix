{
  config,
  ...
}:
{
  # AtlasUponRaiden nix configuration
  # Configures build capabilities and features for remote builder functionality

  nix.settings.system-features = config.systemConstants.atlas.systemFeatures;
}
