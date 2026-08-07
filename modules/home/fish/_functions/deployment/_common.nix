{
  domain,
  ...
}:
{
  __deploymentPingHost = ''
    set -l target $argv[1]
    set -l ping_host "$target.${domain}"
    set -l ssh_ping_host (ssh -G $target 2>/dev/null | string match -r "^[Hh]ostname " | string replace -r "^[Hh]ostname " "")
    if test -n "$ssh_ping_host"
      set ping_host $ssh_ping_host
    end
    echo $ping_host
  '';
}
