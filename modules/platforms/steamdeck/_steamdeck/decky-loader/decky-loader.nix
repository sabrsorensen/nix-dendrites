{ ... }:
let
  # Jovian provides Decky's service and option surface. Keep the base platform
  # limited to the upstream loader; plugin packages are separate opt-in work.
  module =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.platform == "steamdeck" && config.my.host.features.deckyLoader) (
      import ./_steamdeck-decky-loader.nix args
    );
in
module
