{ inputs, ... }:
{
  flake.modules.nixos.home-fish =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
      deployment = config.my.deployment;
      hasLocalNhs = deployment.localFlakePath != null;
      canDeployRemotely = deployment.canDeployRemotely && hasLocalNhs;
      domain = builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile "${inputs.nix-secrets}/domain.txt"
      );
      configurationName = lib.toLower host.name;
      inhibitSleep = deployment.sleepy;
      systemdInhibit = lib.getExe' pkgs.systemd "systemd-inhibit";
      isSteamDeck = host.platform == "steamdeck";
      hasPodman = host.features.podman;
    in
    lib.mkIf host.home.enable (
      import ./_content.nix (
        args
        // {
          inherit
            canDeployRemotely
            configurationName
            deployment
            domain
            hasLocalNhs
            hasPodman
            host
            inhibitSleep
            isSteamDeck
            systemdInhibit
            username
            ;
        }
      )
    );
}
