{
  deployment,
  domain,
  ...
}:
{
  nhSwitchRemote = ''
    set target_host_lower (string lower $argv[1])
    inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host "nix-$target_host_lower" --keep-going $argv[2..-1]
  '';
  nhSwitchUpgradeRemote = ''
    set target_host_lower (string lower $argv[1])
    inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host "nix-$target_host_lower" --update --keep-going $argv[2..-1]
  '';
  nhBuildThenSwitchRemote = ''
    set target_host $argv[1]
    if test -z "$target_host"
      echo "Usage: <command> <target_host> [additional_args...]"
      return 1
    end
    set target_host_lower (string lower $target_host)
    set switch_target_host "nix-$target_host_lower"
    set ping_host "$target_host.${domain}"
    set ssh_ping_host (ssh -G $target_host 2>/dev/null | string match -r "^[Hh]ostname " | string replace -r "^[Hh]ostname " "")
    if test -n "$ssh_ping_host"
      set ping_host $ssh_ping_host
    end
    echo "🔨 Building $target_host locally before waiting for it to come online..."
    inhibitSleep nh os build ${deployment.localFlakePath} -H $target_host_lower --keep-going $argv[2..-1]
    or return $status
    if command -sq notify-send
      notify-send "Steam Deck build complete" "Turn on $target_host. Deployment will continue after it responds to ping."
    end
    echo "Build completed for $target_host."
    echo "Turn on $target_host, then press Enter to start waiting for network reachability."
    read
    echo "Waiting for $target_host at $ping_host to respond to ping..."
    while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
      sleep 5
    end
    echo "$target_host is reachable. Starting remote switch..."
    inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host $switch_target_host --keep-going $argv[2..-1]
  '';
  nhBuildThenSwitchUpgradeRemote = ''
    set target_host $argv[1]
    if test -z "$target_host"
      echo "Usage: <command> <target_host> [additional_args...]"
      return 1
    end
    set target_host_lower (string lower $target_host)
    set switch_target_host "nix-$target_host_lower"
    set ping_host "$target_host.${domain}"
    set ssh_ping_host (ssh -G $target_host 2>/dev/null | string match -r "^[Hh]ostname " | string replace -r "^[Hh]ostname " "")
    if test -n "$ssh_ping_host"
      set ping_host $ssh_ping_host
    end
    echo "🔨 Building $target_host locally before waiting for it to come online..."
    inhibitSleep nh os build ${deployment.localFlakePath} -H $target_host_lower --update --keep-going $argv[2..-1]
    or return $status
    if command -sq notify-send
      notify-send "Steam Deck build complete" "Turn on $target_host. Deployment will continue after it responds to ping."
    end
    echo "Build completed for $target_host."
    echo "Turn on $target_host, then press Enter to start waiting for network reachability."
    read
    echo "Waiting for $target_host at $ping_host to respond to ping..."
    while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
      sleep 5
    end
    echo "$target_host is reachable. Starting remote switch..."
    inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host $switch_target_host --update --keep-going $argv[2..-1]
  '';
}
