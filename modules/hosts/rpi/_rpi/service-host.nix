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
  mkSecretsSshKeyFiles = inputs.self.lib.shared.mkSecretsSshKeyFiles;
  moduleBuilders = import ../_module-builders.nix { inherit inputs lib; };
  static = mkStaticModule {
    inherit hostName address nameservers;
  };
  inherit (moduleBuilders) mkBaseModule mkStaticModule;
in
{ config, ... }:
{
  imports = [
    (mkBaseModule hostName)
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
