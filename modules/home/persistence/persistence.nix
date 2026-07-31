{ ... }:
{
  flake.modules.nixos.home-persistence =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
    in
    lib.mkIf (host.home.enable && host.features.persistenceHome) (
      import ./_content.nix (args // { inherit username; })
    );
}
