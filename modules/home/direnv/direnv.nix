{ ... }:
{
  flake.modules.nixos.home-direnv =
    {
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
    in
    lib.mkIf (host.home.enable && config.my.deployment.localFlakePath != null) {
      home-manager.users.${host.home.username}.programs.direnv = import ./_content.nix;
    };
}
