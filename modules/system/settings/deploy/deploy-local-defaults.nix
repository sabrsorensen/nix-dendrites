{
  ...
}:
{
  flake.modules.nixos."deploy-local-defaults" =
    { config, lib, ... }:
    {
      my.host.deploy.localFlakePath = lib.mkDefault "/home/sam/src/nix-dendrites";

      programs.nh = lib.mkIf (config.my.host.deploy.localFlakePath != null) {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = config.my.host.deploy.localFlakePath;
      };
    };
}
