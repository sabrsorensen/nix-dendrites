{
  cfg,
  lib,
  pkgs,
  zoneStaticRecords,
  ...
}:
{
  assertions = [
    {
      assertion =
        builtins.length (lib.unique (map (record: record.hostname) zoneStaticRecords))
        == builtins.length zoneStaticRecords;
      message = "my.dhcpCoredns static and published DNS records contain duplicate hostnames.";
    }
  ];

  environment.systemPackages = with pkgs; [
    jq
    python3
    sops
    ssh-to-age
  ];

  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir} 0755 root root -"
  ];
}
