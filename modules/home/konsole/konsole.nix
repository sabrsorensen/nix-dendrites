{ ... }:
{
  flake.modules.nixos.konsole =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.my.host.home.username;
    in
    lib.mkIf (config.my.host.features.konsole && config.my.host.home.enable) {
      home-manager.users.${username} = import ./_content.nix { inherit pkgs; };
    };
}
