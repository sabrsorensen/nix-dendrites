{ ... }:
let
  module =
    args@{
      config,
      lib,
      ...
    }:
    lib.mkIf (
      config.my.host.platform == "steamdeck" && builtins.elem "steamdeck-dualboot" config.my.host.tags
    ) (import ./_dualboot-content.nix args);
in
module
