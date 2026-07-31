{ ... }:
{
  flake.modules.nixos.home-github-cli =
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
      home-manager.users.${username}.programs.gh = import ./_content.nix;
    };
}
