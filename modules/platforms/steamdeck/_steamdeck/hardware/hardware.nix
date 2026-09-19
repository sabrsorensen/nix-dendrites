{ ... }:
let
  module =
    args@{
      config,
      lib,
      ...
    }:
    lib.mkIf (config.my.host.platform == "steamdeck") (import ./_hardware.nix args);
in
module
