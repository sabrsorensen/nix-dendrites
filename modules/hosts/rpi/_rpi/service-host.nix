{
  inputs,
  lib,
}:
{
  hostName,
  address,
  nameservers,
  serviceImports,
  samAuthorizedKeys,
  nixRemoteAuthorizedKeys,
  adguardDhcpEnabled,
}:
let
  rpi = inputs.self.lib.rpi;
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

  users.users.sam.openssh.authorizedKeys.keyFiles = samAuthorizedKeys;

  users.users.nix-remote = lib.mkIf (config ? sops && config.sops.secrets ? hashed_password) {
    openssh.authorizedKeys.keyFiles = nixRemoteAuthorizedKeys;
  };

  services.adguardhome.settings.dhcp.enabled = adguardDhcpEnabled;
}
