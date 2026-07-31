{ ... }:
{
  flake.modules.nixos.home-vim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
    in
    lib.mkIf host.home.enable {
      home-manager.users.${username}.programs.vim =
        (import ./_content.nix { inherit pkgs; }).programs.vim;
    };
}
