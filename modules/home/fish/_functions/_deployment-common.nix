{
  domain ? "",
  systemdInhibit,
  ...
}:
{
  inhibitSleep = ''
    echo "🔒 Inhibiting sleep for: $argv"
    echo -ne "\033]0;$argv\007"
    ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who="$USER" --why=nixos-deployment --mode=block $argv
  '';
  __deployWaitForTarget = ''
    set -l target $argv[1]
    set -l ping_host "$target.${domain}"
    echo "Turn on $target, then press Enter to start waiting for network reachability."
    read
    echo "Waiting for $target at $ping_host to respond to ping..."
    while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
      sleep 5
    end
    echo "$target is reachable. Starting remote deployment..."
  '';
}
