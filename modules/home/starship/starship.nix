{ ... }:
{
  flake.modules.nixos.home-starship =
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
      home-manager.users.${username}.programs.starship =
        (import ./_content.nix { inherit lib; }).programs.starship;
    };
}
