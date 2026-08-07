{ config, pkgs, ... }:
let
  username = config.my.host.home.username;
  homeDirectory = config.my.host.home.homeDirectory;
in
{
  users.groups.${username} = { };
  users.users.${username} = {
    isNormalUser = true;
    description = "Sam";
    home = homeDirectory;
    shell = pkgs.bash;
    group = username;
  };
}
