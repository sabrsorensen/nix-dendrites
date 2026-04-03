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
    set nh_target_host (string lower $target_host)
    if test "$tail" = true
        set nh_target_host "$nh_target_host-tail"
    end
    set nh_target_host "nix-$nh_target_host"

    set upgrade_flag ""
    if test "$upgrade" = true
        set upgrade_flag --update
    end

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

    # Check if peer AdGuardHome DNS is responding
    if not timeout 10 dig @$peer_ip -p 53 google.com +short >/dev/null 2>&1
        echo "❌ ERROR: $peer_name AdGuardHome DNS is not responding!"
        echo "   Refusing to deploy - peer must be healthy before deployment"
        return 1
    end

    # Check AGH-PDNS integration on peer
    for domain in "naboo.nesneros.space" "nevarro.nesneros.space" "atlasuponraiden.nesneros.space"
        if not timeout 10 dig @$peer_ip -p 53 $domain +short >/dev/null 2>&1
            echo "❌ ERROR: $peer_name cannot resolve $domain (AGH-PDNS integration issue)!"
            return 1
        end
    end

    # Check if peer has deployment lock
    set lock_file "/tmp/.deploy-lock"
    if ssh nix-(string lower $peer_name) "test -f $lock_file" 2>/dev/null
        echo "❌ ERROR: Deployment already in progress on $peer_name!"
        echo "   Lock file exists: $lock_file"
        return 1
    end

    # Create our deployment lock on target
    if not ssh nix-(string lower $target_host) "echo '(date): Deploying from (hostname)' > $lock_file" 2>/dev/null
        echo "❌ ERROR: Failed to create deployment lock on $target_host"
        return 1
    end

    echo "✅ Safety checks passed - deploying to $target_host"

    # Run the actual deployment
    set deploy_result 0
    nh os switch ~/src/nix-dendrites/ -H $target_host --target-host $nh_target_host $upgrade_flag --keep-going $additional_args
    set deploy_result $status

    if test $deploy_result -eq 0
        echo "🔍 Running post-deployment validation on $target_host..."
        sleep 10

        # Post-deployment health checks
        if not ssh $nh_target_host 'timeout 10 dig @127.0.0.1 -p 53 google.com +short' >/dev/null 2>&1
            echo (ssh $nh_target_host 'timeout 10 dig @127.0.0.1 -p 53 google.com +short')
            echo "❌ CRITICAL: Post-deployment DNS check failed on $target_host!"
            ssh nix-(string lower $target_host) "rm -f $lock_file" 2>/dev/null
            return 1
        end

        # Test AGH-PDNS integration post-deployment
        for domain in "naboo.nesneros.space" "nevarro.nesneros.space" "atlasuponraiden.nesneros.space"
            if not ssh $nh_target_host "timeout 10 dig @127.0.0.1 -p 53 $domain +short" >/dev/null 2>&1
                echo "❌ CRITICAL: Post-deployment AGH-PDNS integration check failed for $domain!"
                ssh nix-(string lower $target_host) "rm -f $lock_file" 2>/dev/null
                return 1
            end
        end

        echo "✅ Deployment to $target_host completed successfully"
    else
        echo "❌ Deployment to $target_host failed"
    end

    # Always clean up deployment lock
    ssh nix-(string lower $target_host) "rm -f $lock_file" 2>/dev/null
    return $deploy_result
end
