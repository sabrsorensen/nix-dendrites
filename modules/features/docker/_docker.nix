{ config, lib, ... }:
let
  hasSam = config.my.host.home.enable && config.my.host.platform != "wsl";
in
{
  virtualisation.docker.enable = true;
  users.users.sam.extraGroups = lib.mkIf hasSam (lib.mkAfter [ "docker" ]);
}
