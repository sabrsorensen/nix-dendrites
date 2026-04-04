{
  inputs,
  lib,
  ...
}:
{ config, ... }:
{
  home-manager.users.${config.my.wslUsername} = {
    imports = [
      inputs.self.modules.homeManager."NixOS-WSL"
    ];
    home.username = lib.mkDefault config.my.wslUsername;
    home.homeDirectory = lib.mkDefault "/home/${config.my.wslUsername}";
  };
}
