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
        import ./_content.nix args
      );
    };
in
module
