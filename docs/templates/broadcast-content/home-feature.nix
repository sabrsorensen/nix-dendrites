# modules/home/example/example.nix
{ ... }:
{
  flake.modules.nixos.home-example =
    args@{
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
    in
    {
      config = lib.mkIf (host.home.enable && host.features.example) {
        home-manager.users.${username} = import ./_content.nix args;
      };
    };
}

# modules/home/example/_content.nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.example ];
}
