{ inputs, ... }:
{
  flake.modules.nixos.home-steamdeck =
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
    lib.mkIf (host.home.enable && host.platform == "steamdeck") (
      import ./_content.nix (args // { inherit inputs username; })
    );
}
