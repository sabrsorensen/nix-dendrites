{ ... }:
let
  module =
    args@{
      config,
      lib,
      ...
    }:
    lib.mkIf (
      config.my.host.platform == "steamdeck" && builtins.elem "steamdeck-singleboot" config.my.host.tags
    ) (import ./_singleboot-content.nix args);
in
module
