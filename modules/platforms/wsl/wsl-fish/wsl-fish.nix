{ ... }:
{
  flake.modules.nixos.wsl-fish =
    {
      config,
      lib,
      ...
    }:
    let
      username = config.my.host.home.username;
    in
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) {
      home-manager.users.${username}.programs.fish = import ./_content.nix { };
    };
}
