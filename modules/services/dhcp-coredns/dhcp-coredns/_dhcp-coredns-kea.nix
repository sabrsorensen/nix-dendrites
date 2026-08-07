{
  cfg,
  dynamicLeasePath,
  keaConfPath,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.dhcp-coredns-kea = {
    description = "Kea DHCP4 server (runtime-generated config)";
    after = [
      "dhcp-coredns-prepare.service"
      "network.target"
    ];
    requires = [ "dhcp-coredns-prepare.service" ];
    wantedBy = lib.optionals cfg.startKeaOnBoot [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kea}/bin/kea-dhcp4 -c ${keaConfPath}";
      Environment = "KEA_DHCP_DATA_DIR=${cfg.stateDir}";
      RuntimeDirectory = "kea";
      Restart = "on-failure";
    };
  };

  systemd.tmpfiles.rules = [
    "f ${dynamicLeasePath} 0644 root root -"
  ];
}
