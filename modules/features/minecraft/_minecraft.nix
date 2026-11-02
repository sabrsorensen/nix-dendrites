{
  inputs,
  lib,
  pkgs,
}:
{
  networking.firewall = {
    allowedTCPPorts = [ 19132 19133 25565 ];
    # 4445: Java clients listen here for LAN server announcements.
    allowedUDPPorts = [ 4445 19132 19133 ];
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
