{ inputs, ... }:
{
  flake.modules.nixos.home-git =
    args@{
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
      gitIdentityPath =
        if host.platform == "wsl" then
          inputs.nix-work-secrets
        else if host.home.enable then
          inputs.nix-secrets
        else
          null;
    in
    lib.mkIf host.home.enable (
      import ./_content.nix (
        args
        // {
          inherit
            inputs
            gitIdentityPath
            username
            ;
          enableCoreWhitespace = host.platform != "wsl";
        }
      )
    );
}
