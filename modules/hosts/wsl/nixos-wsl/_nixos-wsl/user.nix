{ config, pkgs, ... }:
{
  users.groups.${config.my.wslUsername} = { };
  users.users.${config.my.wslUsername} = {
    isNormalUser = true;
    home = "/home/${config.my.wslUsername}";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    group = config.my.wslUsername;
  };
}
