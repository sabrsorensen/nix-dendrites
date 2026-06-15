{
  inputs,
  lib,
}:
{
  hostName,
  address,
  nameservers,
  serviceImports,
  samAuthorizedKeyPaths,
  nixRemoteAuthorizedKeyPaths,
}:
let
  rpi = inputs.self.lib.rpi;
  mkSecretsSshKeyFiles = inputs.self.lib.mkSecretsSshKeyFiles;
  static = rpi.mkStaticModule {
    inherit hostName address nameservers;
  };
in
{ config, ... }:
{
  imports = [
    (rpi.mkBaseModule hostName)
  ]
  ++ static.imports
  ++ serviceImports;

  networking = static.networking;

  my.host.address = address;
  my.host.deploy.enableRemoteUser = true;

  users.users.sam.openssh.authorizedKeys.keyFiles = mkSecretsSshKeyFiles samAuthorizedKeyPaths;

  users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
    openssh.authorizedKeys.keyFiles = mkSecretsSshKeyFiles nixRemoteAuthorizedKeyPaths;
  };
}
