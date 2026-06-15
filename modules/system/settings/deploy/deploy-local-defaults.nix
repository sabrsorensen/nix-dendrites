{
  ...
}:
{
  flake.modules.nixos."deploy-local-defaults" =
    { config, lib, ... }:
    let
      localUser =
        if config.my.host.deploy.localUser != null then
          config.my.host.deploy.localUser
        else
          config.my.host.primaryInteractiveUser;
      localUserHome =
        if localUser == null then
          null
        else if builtins.hasAttr localUser config.users.users && config.users.users.${localUser} ? home then
          config.users.users.${localUser}.home
        else
          "/home/${localUser}";
    in
    {
      my.host.deploy.localFlakePath = lib.mkDefault (
        if localUserHome == null then null else "${localUserHome}/src/${config.my.host.deploy.repoName}"
      );

      programs.nh = lib.mkIf (config.my.host.deploy.localFlakePath != null) {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = config.my.host.deploy.localFlakePath;
      };
    };
}
