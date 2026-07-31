{ inputs, ... }:
{
  flake.modules.nixos.home-atuin =
    {
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
      domain = builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile "${inputs.nix-secrets}/domain.txt"
      );
      username = host.home.username;
    in
    lib.mkIf (host.home.enable && host.features.atuin && host.platform != "wsl") {
      home-manager.users.${username}.programs.atuin =
        (import ./_content.nix { inherit domain; }).programs.atuin;
    };
}
