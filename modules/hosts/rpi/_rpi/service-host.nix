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
  moduleBuilders = import ../_module-builders.nix { inherit inputs lib; };
  static = mkStaticModule {
    inherit hostName address nameservers;
  };
  inherit (moduleBuilders) mkBaseModule mkStaticModule;
in
{ config, ... }:
let
  sshKeyHelpers = import ../../_ssh-key-helpers.nix { inherit config; };
in
{
  imports = [
    (mkBaseModule hostName)
  ]
  ++ static.imports
  ++ serviceImports;

  networking = static.networking;

  my.host.address = address;
  my.host.deploy.enableRemoteUser = true;

  users.users.sam.openssh.authorizedKeys.keyFiles = sshKeyHelpers.mkBuildSecretSshKeyFiles samAuthorizedKeyPaths;

  users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
    openssh.authorizedKeys.keyFiles = sshKeyHelpers.mkBuildSecretSshKeyFiles nixRemoteAuthorizedKeyPaths;
  };
}
