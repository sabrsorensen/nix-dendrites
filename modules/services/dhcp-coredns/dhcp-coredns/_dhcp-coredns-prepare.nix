{
  cfg,
  collectLeases,
  dynamicLeaseFileName,
  dynamicLeasePath,
  keaConfPath,
  leasesFile,
  localDomain,
  networkConfig,
  pkgs,
  python3Bin,
  renderZone,
  staticDnsRecords,
  staticLeasesPath,
  mergedRecordsPath,
  zonePath,
  ...
}:
{
  systemd.services.dhcp-coredns-prepare = {
    description = "Prepare Kea config inputs and CoreDNS zone data";
    wantedBy = [ "multi-user.target" ];
    before = [
      "dhcp-coredns-kea.service"
      "coredns.service"
    ];
    after = [
      "network.target"
      "local-fs.target"
    ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -eu

      TEMP_AGE_KEY="/tmp/dhcp-coredns-age-key-$$.txt"
      ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < /etc/ssh/ssh_host_ed25519_key > "$TEMP_AGE_KEY"

      if ! SOPS_AGE_KEY_FILE="$TEMP_AGE_KEY" ${pkgs.sops}/bin/sops --decrypt "${leasesFile}" > "${staticLeasesPath}" 2>/dev/null; then
        echo '{"version":1,"reservations":[]}' > "${staticLeasesPath}"
      fi
      rm -f "$TEMP_AGE_KEY"

      if [ ! -s "${staticLeasesPath}" ]; then
        echo '{"version":1,"reservations":[]}' > "${staticLeasesPath}"
      fi

      if [ ! -f "${dynamicLeasePath}" ]; then
        : > "${dynamicLeasePath}"
      fi

      export GATEWAY="${networkConfig.gateway}"
      export SUBNET_MASK="${networkConfig.subnet_mask}"
      SUBNET_CIDR="$(${python3Bin} - <<'PY'
      import os
      import ipaddress
      network = ipaddress.IPv4Network((os.environ["GATEWAY"], os.environ["SUBNET_MASK"]), strict=False)
      print(str(network))
      PY
      )"

      ${pkgs.jq}/bin/jq '
        {
          "Dhcp4": {
            "interfaces-config": { "interfaces": [ "'"${cfg.interface}"'" ] },
            "lease-database": { "type": "memfile", "persist": true, "name": "'"${dynamicLeaseFileName}"'" },
            "subnet4": [
              {
                "id": 1,
                "subnet": "'"$SUBNET_CIDR"'",
                "pools": [ { "pool": "'"${networkConfig.dhcp_start} - ${networkConfig.dhcp_end}"'" } ],
                "option-data": [
                  { "name": "routers", "data": "'"${networkConfig.gateway}"'" },
                  { "name": "domain-name-servers", "data": "'"${networkConfig.dns_servers}"'" },
                  { "name": "domain-name", "data": "'"${localDomain}"'" }
                ],
                "reservations": (((.reservations // [])
                  | map(select(.ip and .mac)
                    | { "hw-address": (.mac|ascii_downcase), "ip-address": .ip }))
                  + ((.leases // [])
                    | map(select(.static == true and .ip and .mac)
                      | { "hw-address": (.mac|ascii_downcase), "ip-address": .ip })))
              }
            ],
            "valid-lifetime": 3600,
            "renew-timer": 900,
            "rebind-timer": 1800
          }
        }
      ' "${staticLeasesPath}" > "${keaConfPath}"

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
    '';
  };
}
