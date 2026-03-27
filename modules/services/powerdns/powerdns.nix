{
  flake.modules.nixos.powerdns =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      python3Bin = "${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python3";
      domain = config.systemConstants.domain;
      networkConfig = config.systemConstants.network;
    in
    {
      services.powerdns = {
        enable = true;
        extraConfig = ''
          launch=pipe
          pipe-command=/run/pdns/pipe-backend.py
          pipe-timeout=2000
          pipe-regex=

          cache-ttl=0
          query-cache-ttl=0
          negquery-cache-ttl=0
          zone-cache-refresh-interval=0

          local-address=127.0.0.1
          local-port=5335

          socket-dir=/run/pdns

          log-dns-queries=no
          loglevel=4

          receiver-threads=1
          distributor-threads=1

          chroot=
          security-poll-suffix=

          expand-alias=no
          resolver=no
        '';
      };

      systemd.services.pdns.preStart = lib.mkBefore ''
        cp ${./pipe-backend.py} /run/pdns/pipe-backend.py
        chmod +x /run/pdns/pipe-backend.py
        sed -i '1s|#!/usr/bin/env python3|#!${python3Bin}|' /run/pdns/pipe-backend.py
        sed -i 's|ZONE_NAME = "dummydomain"|ZONE_NAME = "${domain}"|' /run/pdns/pipe-backend.py
        sed -i 's|"ns1placeholder"|"${networkConfig.naboo}"|g' /run/pdns/pipe-backend.py
        sed -i 's|"ns2placeholder"|"${networkConfig.nevarro}"|g' /run/pdns/pipe-backend.py
        chown pdns:pdns /run/pdns/pipe-backend.py
      '';

      systemd.tmpfiles.rules = [
        "d /run/pdns 0755 pdns pdns -"
      ];
    };
}
