{
  collectLeases,
  dynamicLeasePath,
  localDomain,
  python3Bin,
  renderZone,
  staticDnsRecords,
  staticLeasesPath,
  mergedRecordsPath,
  zonePath,
  ...
}:
{
  systemd.services.dhcp-coredns-sync = {
    description = "Sync DHCP leases into CoreDNS records";
    after = [
      "dhcp-coredns-kea.service"
      "coredns.service"
    ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -eu
      ${python3Bin} ${collectLeases} \
        --static-leases "${staticLeasesPath}" \
        --backend "kea-dhcp4" \
        --dynamic-leases "${dynamicLeasePath}" \
        --output "${mergedRecordsPath}"

      ${python3Bin} ${renderZone} \
        --domain "${localDomain}" \
        --records "${mergedRecordsPath}" \
        --static-records-json '${staticDnsRecords}' \
        --zone "${zonePath}" \
        --ns "ns1" \
        --ns2 "ns2"

      systemctl reload coredns.service || systemctl restart coredns.service
    '';
  };

  systemd.timers.dhcp-coredns-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
      Unit = "dhcp-coredns-sync.service";
    };
  };
}
