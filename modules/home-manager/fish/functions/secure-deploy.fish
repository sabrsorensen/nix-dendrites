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

    # Set up variables
    set peer_ip ""
    set peer_name ""
    set lock_host "nix-(string lower $target_host)"
    set nh_target_host (string lower $target_host)
    set local_domains "naboo.nesneros.space" "nevarro.nesneros.space" "atlasuponraiden.nesneros.space"
    if test "$tail" = true
        set nh_target_host "$nh_target_host-tail"
    end
    set nh_target_host "nix-$nh_target_host"

    # Determine peer based on target
    switch $target_host
        case Naboo
            set peer_ip "192.168.1.4"
            set peer_name Nevarro
        case Nevarro
            set peer_ip "192.168.1.3"
            set peer_name Naboo
        case "*"
            echo "Unknown target host: $target_host"
            return 1
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

    # Check peer service health for the current DNS/DHCP topology
    switch $peer_name
        case Nevarro
            if not ssh nix-(string lower $peer_name) "systemctl is-active --quiet blocky && systemctl is-active --quiet coredns && systemctl is-active --quiet dhcp-coredns-kea" 2>/dev/null
                echo "❌ ERROR: $peer_name is not healthy for primary DNS/DHCP duty!"
                echo "   Expected active services: blocky, coredns, dhcp-coredns-kea"
                return 1
            end
        case Naboo
            if not ssh nix-(string lower $peer_name) "systemctl is-active --quiet blocky && systemctl is-active --quiet coredns && systemctl is-active --quiet dhcp-failover.timer" 2>/dev/null
                echo "❌ ERROR: $peer_name is not healthy for primary DNS / standby DHCP duty!"
                echo "   Expected active services: blocky, coredns, dhcp-failover.timer"
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

    if ssh nix-(string lower $peer_name) "test -f $lock_file" 2>/dev/null
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
        nh os switch ~/src/nix-dendrites/ -H $target_host --target-host $nh_target_host --update --keep-going $additional_args
    else
        nh os switch ~/src/nix-dendrites/ -H $target_host --target-host $nh_target_host --keep-going $additional_args
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
        switch $target_host
            case Naboo
                if not ssh $nh_target_host "systemctl is-active --quiet blocky && systemctl is-active --quiet coredns && systemctl is-active --quiet dhcp-failover.timer" 2>/dev/null
                    echo "❌ CRITICAL: Post-deployment service health check failed on $target_host!"
                    echo "   Expected active services: blocky, coredns, dhcp-failover.timer"
                    __secure_deploy_cleanup_lock
                    functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit
                    return 1
                end
            case Nevarro
                if not ssh $nh_target_host "systemctl is-active --quiet blocky && systemctl is-active --quiet coredns && systemctl is-active --quiet dhcp-coredns-kea" 2>/dev/null
                    echo "❌ CRITICAL: Post-deployment service health check failed on $target_host!"
                    echo "   Expected active services: blocky, coredns, dhcp-coredns-kea"
                    __secure_deploy_cleanup_lock
                    functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit
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
    functions -e __secure_deploy_cleanup_lock __secure_deploy_cleanup_on_signal __secure_deploy_cleanup_on_exit
    return $deploy_result
end
