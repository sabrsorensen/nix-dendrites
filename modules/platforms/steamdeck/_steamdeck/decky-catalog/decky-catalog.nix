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
      options.my.host.features.deckyCatalog = lib.mkEnableOption "declarative Decky plugin catalogue";
      config = lib.mkIf (config.my.host.platform == "steamdeck" && config.my.host.features.deckyCatalog) (
        import ./_steamdeck-decky-catalog.nix args
      );
    };
in
module
