{
  inputs,
  lib,
  pkgs,
}:
{
  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
  };
  # Bedrock on Linux bundles its own Wine (independent of features.wine) and
  # warns about poor performance without /dev/ntsync.
  boot.kernelModules = [ "ntsync" ];
  environment.systemPackages =
    with pkgs;
    [
      prismlauncher
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
