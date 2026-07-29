{ inputs, ... }:
{
  flake.modules.nixos.nixos-wsl =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.platform == "wsl") {
      users.groups.ssorensen = { };
      users.users.ssorensen = {
        isNormalUser = true;
        home = "/home/ssorensen";
        extraGroups = [ "wheel" ];
        shell = pkgs.bash;
        group = "ssorensen";
      };
    };
}
