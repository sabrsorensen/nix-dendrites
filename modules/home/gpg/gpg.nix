{ inputs, ... }:
{
  flake.modules.nixos.home-gpg =
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
      home-manager.users.${username} = import ./_content.nix {
        inherit inputs lib pkgs;
        isWsl = host.platform == "wsl";
        secretRoot = if host.platform == "wsl" then inputs.nix-work-secrets else inputs.nix-secrets;
      };
    };
}
