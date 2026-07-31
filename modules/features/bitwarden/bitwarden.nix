{ ... }:
{
  flake.modules.nixos.bitwarden =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.my.host.home.username;
    in
    lib.mkIf config.my.host.features.bitwarden (
      lib.mkMerge [
        (import ./_nixos-content.nix args)
        (lib.mkIf config.my.host.home.enable {
          home-manager.users.${username} = import ./_home-content.nix args;
        })
      ]
    );
}
