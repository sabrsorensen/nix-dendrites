{ inputs, ... }:
{
  flake.modules.nixos.home-sops =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
      homeDirectory = host.home.homeDirectory;
      isManagedPersonal = host.home.enable && host.platform != "wsl";
    in
    lib.mkIf (host.home.enable && host.platform != "wsl") (
      import ./_content.nix (
        args
        // {
          inherit
            homeDirectory
            inputs
            isManagedPersonal
            username
            ;
        }
      )
    );
}
