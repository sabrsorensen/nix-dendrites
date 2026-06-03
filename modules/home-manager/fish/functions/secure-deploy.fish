function secure-deploy --description "Remote deployment script with safety checks"
    # Usage: secure-deploy [--upgrade] [--tail] <target_host> [additional_args...]

    set upgrade false
    set tail false
    set target_host ""
    set additional_args

    # Parse arguments
    for arg in $argv
        switch $arg
            case --upgrade
                set upgrade true
            case --tail
                set tail true
            case "*"
                if test -z "$target_host"
                    set target_host $arg
                else
                    set additional_args $additional_args $arg
                end
        end
    end

    if test -z "$target_host"
        echo "Usage: secure-deploy [--upgrade] [--tail] <target_host> [additional_args...]"
        return 1
    end

    set config_json (secureDeployConfig $target_host)
    if test $status -ne 0 -o -z "$config_json"
        echo "No secure deployment topology is defined for $target_host"
        return 1
    end

    set target_host_lower (string lower $target_host)
    set lock_host "nix-$target_host_lower"
    set nh_target_host $target_host_lower
    set peer_ip (printf '%s\n' "$config_json" | jq -r '.peerIp')
    set peer_name (printf '%s\n' "$config_json" | jq -r '.peerName')
    set local_domains (printf '%s\n' "$config_json" | jq -r '.probeDomains[]')
    set peer_services (printf '%s\n' "$config_json" | jq -r '.peerServices[]')
    set target_services (printf '%s\n' "$config_json" | jq -r '.targetServices[]')
    if test "$tail" = true
        set nh_target_host "$nh_target_host-tail"
    end
    set nh_target_host "nix-$nh_target_host"

    function __secure_deploy_service_cmd
        set checks
        for service in $argv
            set checks $checks "systemctl is-active --quiet $service"
        end
        string join " && " $checks
    end

    echo "🔍 Checking health of $peer_name ($peer_ip) before deploying to $target_host..."

    # Check if peer DNS is answering public lookups through Blocky
    if not timeout 10 dig @$peer_ip -p 53 google.com +short >/dev/null 2>&1
        echo "❌ ERROR: $peer_name DNS on :53 is not responding!"
        echo "   Refusing to deploy - peer must be healthy before deployment"
        return 1
    end

    # Check local zone resolution through the peer's Blocky -> CoreDNS path
    for domain in $local_domains
        if not timeout 10 dig @$peer_ip -p 53 $domain +short >/dev/null 2>&1
            echo "❌ ERROR: $peer_name cannot resolve $domain through Blocky/CoreDNS!"
            return 1
        end
    end

    # Check peer service health for the current deployment topology
    set peer_service_cmd (__secure_deploy_service_cmd $peer_services)
    if test -n "$peer_service_cmd"
        if not ssh "nix-"(string lower $peer_name) "$peer_service_cmd" 2>/dev/null
            echo "❌ ERROR: $peer_name is not healthy for safe deployment!"
            echo "   Expected active services: "(string join ", " $peer_services)
            functions -e __secure_deploy_service_cmd
            return 1
        end
    end

    # Check if peer has deployment lock
    set lock_file "/tmp/.deploy-lock"
    functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit 2>/dev/null
    function __secure_deploy_cleanup_lock --inherit-variable lock_host --inherit-variable lock_file
        ssh $lock_host "rm -f $lock_file" >/dev/null 2>&1
    end
    function __secure_deploy_cleanup_on_signal --on-signal INT --on-signal TERM --inherit-variable lock_host --inherit-variable lock_file
        __secure_deploy_cleanup_lock
    end
    function __secure_deploy_cleanup_on_exit --on-event fish_exit --inherit-variable lock_host --inherit-variable lock_file
        __secure_deploy_cleanup_lock
    end

    if ssh "nix-"(string lower $peer_name) "test -f $lock_file" 2>/dev/null
        echo "❌ ERROR: Deployment already in progress on $peer_name!"
        echo "   Lock file exists: $lock_file"
        functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit
        return 1
    end

    # Create our deployment lock on target
    if not ssh $lock_host "printf '%s: Deploying from %s\n' \"\$(date)\" \"\$(hostname)\" > $lock_file" 2>/dev/null
        echo "❌ ERROR: Failed to create deployment lock on $target_host"
        functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit
        return 1
    end

    echo "✅ Safety checks passed - deploying to $target_host"

    # Run the actual deployment
    set deploy_result 0
    if test "$upgrade" = true
        nh os switch $DENDRITIC_FLAKE_PATH -H $target_host --target-host $nh_target_host --update --keep-going $additional_args
    else
        nh os switch $DENDRITIC_FLAKE_PATH -H $target_host --target-host $nh_target_host --keep-going $additional_args
    end
    set deploy_result $status

    if test $deploy_result -eq 0
        echo "🔍 Running post-deployment validation on $target_host..."
        sleep 10

        # Post-deployment health checks
        set post_deploy_dns_output (ssh $nh_target_host 'timeout 10 dig @127.0.0.1 -p 53 google.com +short' 2>/dev/null)
        if test $status -ne 0
            if test -n "$post_deploy_dns_output"
                echo $post_deploy_dns_output
            end
            echo "❌ CRITICAL: Post-deployment DNS check failed on $target_host!"
            __secure_deploy_cleanup_lock
            functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit
            return 1
        end

        # Check deployed host service health for the current role
        set target_service_cmd (__secure_deploy_service_cmd $target_services)
        if test -n "$target_service_cmd"
            if not ssh $nh_target_host "$target_service_cmd" 2>/dev/null
                echo "❌ CRITICAL: Post-deployment service health check failed on $target_host!"
                echo "   Expected active services: "(string join ", " $target_services)
                __secure_deploy_cleanup_lock
                functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit __secure_deploy_service_cmd
                return 1
            end
        end

        # Test Blocky -> CoreDNS local zone integration post-deployment
        for domain in $local_domains
            if not ssh $nh_target_host "timeout 10 dig @127.0.0.1 -p 53 $domain +short" >/dev/null 2>&1
                echo "❌ CRITICAL: Post-deployment local DNS integration check failed for $domain!"
                __secure_deploy_cleanup_lock
                functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit
                return 1
            end
        end

        echo "✅ Deployment to $target_host completed successfully"
    else
        echo "❌ Deployment to $target_host failed"
    end

    # Always clean up deployment lock
    __secure_deploy_cleanup_lock
    functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit __secure_deploy_service_cmd
    return $deploy_result
end
