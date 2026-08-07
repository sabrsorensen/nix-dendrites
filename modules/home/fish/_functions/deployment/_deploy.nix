{
  deployment,
  domain,
  inhibitSleep,
  systemdInhibit,
  ...
}:
{
  __secureDeployServiceCmd = ''
    set -l checks
    for service in $argv
      set checks $checks "systemctl is-active --quiet $service"
    end
    string join " && " $checks
  '';
  __deploy = ''
    set -l mode $argv[1]
    set -l target $argv[2]
    if test (count $argv) -lt 2
      echo "Usage: $mode <configuration> [nh arguments...]"
      return 2
    end

    set -l target_lower (string lower $target)
    set -l target_ssh "nix-$target_lower"
    set -l tail false
    set -l additional_args
    for arg in $argv[3..-1]
      if test "$arg" = --tail
        set tail true
      else
        set additional_args $additional_args $arg
      end
    end

    if string match -q '*@*' $target
      __deployHomeManager $mode $target $additional_args
      return $status
    end

    set -l secure_target false
    set -l config_json
    set -l peer_name
    set -l peer_ip
    set -l probe_domains
    set -l peer_services
    set -l target_services
    set -l lock_host $target_ssh
    set -l peer_ssh
    if test "$mode" != unsafe; and contains -- $target_lower naboo nevarro
      set secure_target true
      if test "$target_lower" = naboo
        set config_json '{"peerIp":"192.168.1.4","peerName":"Nevarro","peerServices":["blocky","coredns","dhcp-coredns-kea"],"probeDomains":["naboo.${domain}","nevarro.${domain}","atlasuponraiden.${domain}"],"targetServices":["blocky","coredns","dhcp-failover.timer"]}'
      else
        set config_json '{"peerIp":"192.168.1.3","peerName":"Naboo","peerServices":["blocky","coredns","dhcp-failover.timer"],"probeDomains":["naboo.${domain}","nevarro.${domain}","atlasuponraiden.${domain}"],"targetServices":["blocky","coredns","dhcp-coredns-kea"]}'
      end
      set peer_ip (printf '%s\n' "$config_json" | jq -r '.peerIp')
      set peer_name (printf '%s\n' "$config_json" | jq -r '.peerName')
      set probe_domains (printf '%s\n' "$config_json" | jq -r '.probeDomains[]')
      set peer_services (printf '%s\n' "$config_json" | jq -r '.peerServices[]')
      set target_services (printf '%s\n' "$config_json" | jq -r '.targetServices[]')
      set peer_ssh "nix-"(string lower $peer_name)
      if $tail
        set target_ssh "$target_ssh-tail"
      end

      echo "🔍 Checking health of $peer_name ($peer_ip) before deploying to $target..."
      if not timeout 10 dig @$peer_ip -p 53 google.com +short >/dev/null 2>&1
        echo "❌ ERROR: $peer_name DNS on :53 is not responding!"
        return 1
      end
      for domain_name in $probe_domains
        if not timeout 10 dig @$peer_ip -p 53 $domain_name +short >/dev/null 2>&1
          echo "❌ ERROR: $peer_name cannot resolve $domain_name through Blocky/CoreDNS!"
          return 1
        end
      end
      set -l peer_service_cmd (__secureDeployServiceCmd $peer_services)
      if test -n "$peer_service_cmd"; and not ssh $peer_ssh "$peer_service_cmd" 2>/dev/null
        echo "❌ ERROR: $peer_name is not healthy for safe deployment!"
        echo "   Expected active services: "(string join ", " $peer_services)
        return 1
      end
      if ssh $peer_ssh 'test -f /tmp/.deploy-lock' 2>/dev/null
        echo "❌ ERROR: Deployment already in progress on $peer_name!"
        return 1
      end
      if not ssh $lock_host 'printf "%s: Deploying from %s\\n" "$(date)" "$(hostname)" > /tmp/.deploy-lock'
        echo "Refusing deployment: target deployment lock is present or inaccessible"
        return 1
      end
    end

    function __deployCleanup --inherit-variable lock_host --inherit-variable secure_target
      if test "$secure_target" = true
        ssh $lock_host 'rm -f /tmp/.deploy-lock' >/dev/null 2>&1
      end
    end
    function __deployCleanupSignal --on-signal INT --on-signal TERM
      __deployCleanup
    end
    function __deployCleanupExit --on-event fish_exit
      __deployCleanup
    end

    set -l update_args
    if test "$mode" = upgrade
      set update_args --update
    end
    echo "🔨 Building $target locally before waiting for it to come online..."
    inhibitSleep nh os build ${deployment.localFlakePath} -H $target_lower $update_args --keep-going $additional_args
    set -l result $status
    if test $result -eq 0
      if command -sq notify-send
        notify-send "NixOS build complete" "Turn on $target. Deployment will continue after it responds to ping."
      end
      echo "Build completed for $target."
      __deployWaitForTarget $target
      inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_ssh $update_args --keep-going $additional_args
      set result $status
    end

    if test $result -eq 0; and test "$secure_target" = true
      echo "🔍 Running post-deployment validation on $target..."
      sleep 10
      set -l post_deploy_dns_output (ssh $target_ssh 'timeout 10 dig @127.0.0.1 -p 53 google.com +short' 2>/dev/null)
      if test $status -ne 0
        if test -n "$post_deploy_dns_output"
          echo $post_deploy_dns_output
        end
        echo "❌ CRITICAL: Post-deployment DNS check failed on $target!"
        set result 1
      end
      if test $result -eq 0
        set -l target_service_cmd (__secureDeployServiceCmd $target_services)
        if test -n "$target_service_cmd"; and not ssh $target_ssh "$target_service_cmd" 2>/dev/null
          echo "❌ CRITICAL: Post-deployment service health check failed on $target!"
          echo "   Expected active services: "(string join ", " $target_services)
          set result 1
        end
      end
      if test $result -eq 0
        for domain_name in $probe_domains
          if not ssh $target_ssh "timeout 10 dig @127.0.0.1 -p 53 $domain_name +short" >/dev/null 2>&1
            echo "❌ CRITICAL: Post-deployment local DNS integration check failed for $domain_name!"
            set result 1
            break
          end
        end
      end
      if test $result -eq 0
        echo "✅ Deployment to $target completed successfully"
      end
    end

    __deployCleanup
    functions -e __deployCleanup __deployCleanupSignal __deployCleanupExit
    return $result
  '';
  nhsr = "__deploy switch $argv";
  nhsur = "__deploy upgrade $argv";
  nhsur_unsafe = "__deploy unsafe $argv";
}
