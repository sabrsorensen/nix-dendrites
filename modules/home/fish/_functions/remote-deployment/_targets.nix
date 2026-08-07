{ domain, ... }:
{
  # These compatibility helper names remain available to existing
  # scripts. Their small explicit target map covers the standalone
  # Emerald Echo Home Manager output and named deployment targets.
  remoteDeployMethod = ''
    switch (string lower $argv[1])
      case emeraldecho
        echo build-then-switch
      case naboo nevarro
        echo secure
      case '*'
        echo switch
    end
  '';
  remoteHomeOutput = ''
    switch (string lower $argv[1])
      case emeraldecho
        echo emeraldecho-steamos
    end
  '';
  remoteHomeUser = ''
    switch (string lower $argv[1])
      case atlasuponraiden emeraldecho kamino naboo nevarro zaphodbeeblebrox
        echo sam
    end
  '';
  secureDeployConfig = ''
    switch (string lower $argv[1])
      case naboo
        printf '%s\n' '{"peerIp":"192.168.1.4","peerName":"Nevarro","peerServices":["blocky","coredns","dhcp-coredns-kea"],"probeDomains":["naboo.${domain}","nevarro.${domain}","atlasuponraiden.${domain}"],"targetServices":["blocky","coredns","dhcp-failover.timer"]}'
      case nevarro
        printf '%s\n' '{"peerIp":"192.168.1.3","peerName":"Naboo","peerServices":["blocky","coredns","dhcp-failover.timer"],"probeDomains":["naboo.${domain}","nevarro.${domain}","atlasuponraiden.${domain}"],"targetServices":["blocky","coredns","dhcp-coredns-kea"]}'
      case '*'
        return 1
    end
  '';
}
