{ ... }:
let
  # Keep the Decky plugin catalogue separate from the loader role.  Plugin
  # packages can be added incrementally while this bridge handles the mutable
  # state directory required by Decky itself.
  module =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jovian.decky-loader;
      jsonType =
        let
          valueType = lib.types.nullOr (
            lib.types.oneOf [
              lib.types.bool
              lib.types.int
              lib.types.float
              lib.types.str
              (lib.types.listOf valueType)
              (lib.types.attrsOf valueType)
            ]
          );
        in
        valueType;
    in
    {
      options.my.host.features.deckyPlugins = lib.mkEnableOption "declarative Decky plugin staging";
      options.jovian.decky-loader.plugins = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = { };
        description = "Declarative Decky Loader plugins keyed by their Decky directory name.";
      };
      options.jovian.decky-loader.seededSettings = lib.mkOption {
        type = lib.types.attrsOf jsonType;
        default = { };
        description = "JSON files to preseed under Decky Loader's settings directory.";
      };

      config = import ./_steamdeck-decky-plugins.nix (args // { inherit cfg; });
    };
in
module
