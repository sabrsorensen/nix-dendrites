{
  inputs,
  lib,
  ...
}:
{ config, ... }:
{
  users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/kamino_atlas_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphod_atlas_nix.pub"
    ];
  };
}
