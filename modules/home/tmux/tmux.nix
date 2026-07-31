{ ... }:
{
  flake.modules.nixos.home-tmux =
    {
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
    in
    lib.mkIf host.home.enable {
      home-manager.users.${username}.programs.tmux = (import ./_content.nix).programs.tmux;
    };
}
