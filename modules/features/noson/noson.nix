{ ... }:
{
  flake.modules.nixos.noson =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.my.host.home.username;
    in
    lib.mkIf (config.my.host.features.noson && config.my.host.home.enable) (
      lib.mkMerge [
        (import ./_content.nix args)
        {
          home-manager.users.${username} = import ./_home-content.nix args;
        }
      ]
    );
}
