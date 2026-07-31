{ ... }:
{
  flake.modules.nixos.office =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.my.host.home.username;
    in
    lib.mkIf (config.my.host.features.office && config.my.host.home.enable) {
      home-manager.users.${username} = import ./_content.nix { inherit lib pkgs; };
    };
}
