{
  certEnvironment,
  extraCertFiles,
  lib,
  ...
}:
{
  environment.sessionVariables = certEnvironment;
  systemd.services.nix-daemon.environment = lib.mapAttrs (
    _: value: lib.mkForce value
  ) certEnvironment;
  security.pki.certificateFiles = extraCertFiles;
}
