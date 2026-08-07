{ ... }:
let
  module =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf (config.my.host.platform == "steamdeck" && config.my.host.features.deckyCatalog) (
        import ./_steamdeck-decky-catalog.nix args
      );
    };
in
module
