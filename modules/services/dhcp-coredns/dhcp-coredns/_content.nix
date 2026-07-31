args@{
  cfg,
  lib,
  pkgs,
  networkConfig,
  zoneStaticRecords,
  localDomain,
  ...
}:
let
  python3Bin = "${pkgs.python3}/bin/python3";

  staticLeasesPath = "${cfg.stateDir}/leases.static.json";
  dynamicLeaseFileName = "kea-leases4.csv";
  dynamicLeasePath = "${cfg.stateDir}/${dynamicLeaseFileName}";
  keaConfPath = "${cfg.stateDir}/kea-dhcp4.conf";
  mergedRecordsPath = "${cfg.stateDir}/records.json";
  zonePath = "${cfg.stateDir}/${localDomain}.zone";
  dnsListenMatch = builtins.match "^(.+):([0-9]+)$" cfg.dnsListen;
  dnsHostRaw = builtins.elemAt dnsListenMatch 0;
  dnsHost =
    if lib.hasPrefix "[" dnsHostRaw && lib.hasSuffix "]" dnsHostRaw then
      builtins.substring 1 ((builtins.stringLength dnsHostRaw) - 2) dnsHostRaw
    else
      dnsHostRaw;
  dnsPort = builtins.elemAt dnsListenMatch 1;
  dnsBindDirective =
    if dnsHost == "" || dnsHost == "0.0.0.0" || dnsHost == "::" then "" else "bind ${dnsHost}";
  upstreamServers = builtins.concatStringsSep " " cfg.upstreamServers;
  staticDnsRecords = builtins.toJSON zoneStaticRecords;
  contentArgs = args // {
    inherit
      dnsBindDirective
      dnsPort
      dynamicLeaseFileName
      dynamicLeasePath
      keaConfPath
      mergedRecordsPath
      python3Bin
      staticDnsRecords
      staticLeasesPath
      upstreamServers
      zonePath
      ;
  };
in
lib.mkMerge [
  (import ./_state-content.nix contentArgs)
  (import ./_prepare-content.nix contentArgs)
  (import ./_kea-content.nix contentArgs)
  (import ./_coredns-content.nix contentArgs)
  (import ./_sync-content.nix contentArgs)
  (import ./_firewall-content.nix contentArgs)
]
