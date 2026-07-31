{ inputs, ... }:
{
  flake.modules.nixos.home-ssh =
    args@{
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
      domain = builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile "${inputs.nix-secrets}/domain.txt"
      );
      deployment = config.my.deployment;
      canDeployRemotely = deployment.canDeployRemotely && deployment.localFlakePath != null;
    in
    lib.mkIf host.home.enable (
      import ./_content.nix (
        args
        // {
          inherit
            canDeployRemotely
            domain
            username
            ;
          includeHostBlocks = host.platform != "wsl";
        }
      )
    );
}
