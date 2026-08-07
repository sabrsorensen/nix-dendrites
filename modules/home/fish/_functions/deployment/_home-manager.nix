{
  deployment,
  domain,
  ...
}:
{
  homeManagerSwitchRemote = ''
    set target_spec $argv[1]
    set target_host $target_spec
    if test -z "$target_spec"
      echo "Usage: <command> <target_host|user@target_host> [build_args...]"
      return 1
    end
    set remote_user ""
    if string match -q '*@*' $target_spec
      set remote_user (string split -m1 '@' $target_spec)[1]
      set target_host (string split -m1 '@' $target_spec)[2]
    end
    set home_output (remoteHomeOutput $target_host)
    if test -z "$home_output"
      echo "No remote Home Manager output is defined for $target_host"
      return 1
    end
    if test -z "$remote_user"
      set remote_user (remoteHomeUser $target_host)
    end
    if test -z "$remote_user"
      echo "No remote SSH user is defined for $target_host"
      return 1
    end
    set configured_remote_user (remoteHomeUser $target_host)
    if test "$remote_user" = "$configured_remote_user"
      set remote_target "$target_host"
    else
      set remote_target "$remote_user@$target_host"
    end
    set remote_store_url "ssh://$remote_target?remote-program=/home/$remote_user/.nix-profile/bin/nix-store"
    set remote_method (remoteDeployMethod $target_host)
    set ping_host (__deploymentPingHost $target_host)
    echo "🔨 Building $home_output locally..."
    inhibitSleep nix build ${deployment.localFlakePath}#$home_output $argv[2..-1]
    or return $status
    set store_path (nix path-info ${deployment.localFlakePath}#$home_output)
    or return $status
    if test "$remote_method" = "build-then-switch"
      if command -sq notify-send
        notify-send "Home Manager build complete" "Turn on $target_host. Activation will continue after it responds to ping."
      end
      echo "Build completed for $target_host."
      echo "Turn on $target_host, then press Enter to start waiting for network reachability."
      read
      echo "Waiting for $target_host at $ping_host to respond to ping..."
      while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
        sleep 5
      end
    end
    echo "📦 Copying $home_output to $remote_target..."
    inhibitSleep nix copy --to "$remote_store_url" ${deployment.localFlakePath}#$home_output
    or return $status
    echo "🚀 Activating Home Manager on $remote_target..."
    ssh $remote_target "HOME=/home/$remote_user PATH=/home/$remote_user/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin:\$PATH bash -lc '$store_path/activate'"
  '';
}
