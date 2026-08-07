{
  deployment,
  inhibitSleep,
  systemdInhibit,
  ...
}:
{
  secureDeployChecked = ''
    if test (remoteDeployMethod $argv[1]) = "build-then-switch"
      echo "Use nhsur for Steam Deck deployment"
      return 1
    end
    secure-deploy --upgrade $argv
  '';
  # The guarded RPi deployment path verifies its DNS peer before
  # taking a target-side lock and switching the configuration.
  secure-deploy = ''
    set -l upgrade false
    set -l tail false
    set -l target ""
    set -l additional_args
    for arg in $argv
      switch $arg
        case --upgrade
          set upgrade true
        case --tail
          set tail true
        case '*'
          if test -z "$target"
            set target $arg
          else
            set additional_args $additional_args $arg
          end
      end
    end
    if test -z "$target"
      echo "Usage: secure-deploy [--upgrade] [--tail] <Naboo|Nevarro> [nh arguments...]"
      return 2
    end
    set -l target_lower (string lower $target)
    set -l lock_host "nix-$target_lower"
    set -l target_ssh $lock_host
    if $tail
      set target_ssh "$target_ssh-tail"
    end
    set -l config_json (secureDeployConfig $target)
    if test $status -ne 0 -o -z "$config_json"
      echo "No secure deployment topology is defined for $target"
      return 1
    end
    set -l peer_ip (printf '%s\n' "$config_json" | jq -r '.peerIp')
    set -l peer_name (printf '%s\n' "$config_json" | jq -r '.peerName')
    set -l probe_domains (printf '%s\n' "$config_json" | jq -r '.probeDomains[]')
    set -l peer_services (printf '%s\n' "$config_json" | jq -r '.peerServices[]')
    set -l target_services (printf '%s\n' "$config_json" | jq -r '.targetServices[]')
    set -l peer_ssh "nix-"(string lower $peer_name)
    function __secure_deploy_service_cmd
      set checks
      for service in $argv
        set checks $checks "systemctl is-active --quiet $service"
      end
      string join " && " $checks
    end
    echo "🔍 Checking health of $peer_name ($peer_ip) before deploying to $target..."
    if not timeout 10 dig @$peer_ip -p 53 google.com +short >/dev/null 2>&1
      echo "❌ ERROR: $peer_name DNS on :53 is not responding!"
      functions -e __secure_deploy_service_cmd
      return 1
    end
    for domain in $probe_domains
      if not timeout 10 dig @$peer_ip -p 53 $domain +short >/dev/null 2>&1
        echo "❌ ERROR: $peer_name cannot resolve $domain through Blocky/CoreDNS!"
        functions -e __secure_deploy_service_cmd
        return 1
      end
    end
    set -l peer_service_cmd (__secure_deploy_service_cmd $peer_services)
    if test -n "$peer_service_cmd"
      if not ssh $peer_ssh "$peer_service_cmd" 2>/dev/null
        echo "❌ ERROR: $peer_name is not healthy for safe deployment!"
        echo "   Expected active services: "(string join ", " $peer_services)
        functions -e __secure_deploy_service_cmd
        return 1
      end
    end
    function __secure_deploy_cleanup --inherit-variable lock_host
      ssh $lock_host 'rm -f /tmp/.deploy-lock' >/dev/null 2>&1
    end
    function __secure_deploy_cleanup_signal --on-signal INT --on-signal TERM --inherit-variable lock_host
      __secure_deploy_cleanup
    end
    function __secure_deploy_cleanup_exit --on-event fish_exit --inherit-variable lock_host
      __secure_deploy_cleanup
    end
    if ssh $peer_ssh 'test -f /tmp/.deploy-lock' 2>/dev/null
      echo "❌ ERROR: Deployment already in progress on $peer_name!"
      functions -e __secure_deploy_cleanup __secure_deploy_cleanup_signal __secure_deploy_cleanup_exit __secure_deploy_service_cmd
      return 1
    end
    if not ssh $lock_host 'printf "%s: Deploying from %s\\n" "$(date)" "$(hostname)" > /tmp/.deploy-lock'
      echo "Refusing deployment: target deployment lock is present or inaccessible"
      functions -e __secure_deploy_cleanup __secure_deploy_cleanup_signal __secure_deploy_cleanup_exit __secure_deploy_service_cmd
      return 1
    end
    if $upgrade
      if ${if inhibitSleep then "true" else "false"}
        ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who=secure-deploy --why="NixOS remote deployment" --mode=block nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_ssh --update --keep-going $additional_args
      else
        nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_ssh --update --keep-going $additional_args
      end
    else
      if ${if inhibitSleep then "true" else "false"}
        ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who=secure-deploy --why="NixOS remote deployment" --mode=block nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_ssh --keep-going $additional_args
      else
        nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_ssh --keep-going $additional_args
      end
    end
    set -l result $status
    if test $result -eq 0
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
        set -l target_service_cmd (__secure_deploy_service_cmd $target_services)
        if test -n "$target_service_cmd"
          if not ssh $target_ssh "$target_service_cmd" 2>/dev/null
            echo "❌ CRITICAL: Post-deployment service health check failed on $target!"
            echo "   Expected active services: "(string join ", " $target_services)
            set result 1
          end
        end
      end
      if test $result -eq 0
        for domain in $probe_domains
          if not ssh $target_ssh "timeout 10 dig @127.0.0.1 -p 53 $domain +short" >/dev/null 2>&1
            echo "❌ CRITICAL: Post-deployment local DNS integration check failed for $domain!"
            set result 1
            break
          end
        end
      end
      if test $result -eq 0
        echo "✅ Deployment to $target completed successfully"
      end
    end
    __secure_deploy_cleanup
    functions -e __secure_deploy_cleanup __secure_deploy_cleanup_signal __secure_deploy_cleanup_exit __secure_deploy_service_cmd
    return $result
  '';
}
