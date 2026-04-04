{
  inputs,
  lib,
  ...
}:
{ config, ... }:
let
  enableNixRemote =
    !(config.wsl.enable or false) && config ? sops && config.sops.secrets ? hashed_password;
in
{
  users.users.nix-remote = lib.mkIf enableNixRemote {
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/zaphod_atlas_nix.pub"
    ];
  };
}
