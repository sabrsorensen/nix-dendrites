{
  cfg,
  dnsBindDirective,
  dnsPort,
  lib,
  localDomain,
  networkConfig,
  upstreamServers,
  zonePath,
  ...
}:
{
  services.coredns = {
    enable = true;
    config = ''
      mail.${localDomain}:${dnsPort} {
        log
        errors
        forward . ${upstreamServers}
        cache 60
      }

      ${localDomain}:${dnsPort} {
        log
        errors
        ${lib.optionalString (cfg.localDomainApexIp != null) ''
          hosts {
            ${cfg.localDomainApexIp} ${localDomain}
            ${cfg.localDomainApexIp} @
            fallthrough
          }
        ''}
        file ${zonePath} ${localDomain}
        forward . ${upstreamServers}
        cache 60
      }

      .:${dnsPort} {
        log
        errors
        ${lib.optionalString (dnsBindDirective != "") dnsBindDirective}
        hosts {
          ${networkConfig.gateway} home-gw.${localDomain}
          fallthrough
        }
        file ${zonePath} ${localDomain}
        forward . ${upstreamServers}
        cache 60
      }
    '';
  };
}
