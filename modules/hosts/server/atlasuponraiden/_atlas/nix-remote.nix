{
  inputs,
  lib,
  ...
}:
{ config, ... }:
{
  users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/kamino/atlas_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphod/atlas_nix.pub"
    ];
  };
}
