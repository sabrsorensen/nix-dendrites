{ ... }:
let
  module =
    args@{
      config,
      lib,
      ...
    }:
    lib.mkIf (config.my.host.platform == "steamdeck") (import ./_content.nix args);
in
module
