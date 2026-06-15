{
  inputs,
  lib,
  ...
}:
{ config, ... }:
let
  username = config.my.host.primaryInteractiveUser;
in
{
  home-manager.users.${username} = {
    imports = [
      inputs.self.modules.homeManager."NixOS-WSL"
    ];
    home.username = lib.mkDefault username;
    home.homeDirectory = lib.mkDefault "/home/${username}";
  };
}
