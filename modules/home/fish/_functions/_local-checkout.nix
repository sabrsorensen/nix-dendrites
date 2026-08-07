{
  configurationName,
  deployment,
  inhibitSleep,
  systemdInhibit,
  ...
}:
{
  nhs = ''
    if test (count $argv) -ge 1; and contains -- $argv[1] -j --max-jobs
      if ${if inhibitSleep then "true" else "false"}
        ${systemdInhibit} --what=shutdown:sleep:idle --who=nhs --why="NixOS local switch" --mode=block nh os switch ${deployment.localFlakePath} -H ${configurationName} --keep-going -- $argv
      else
        nh os switch ${deployment.localFlakePath} -H ${configurationName} --keep-going -- $argv
      end
    else if ${if inhibitSleep then "true" else "false"}
      ${systemdInhibit} --what=shutdown:sleep:idle --who=nhs --why="NixOS local switch" --mode=block nh os switch ${deployment.localFlakePath} -H ${configurationName} --keep-going $argv
    else
      nh os switch ${deployment.localFlakePath} -H ${configurationName} --keep-going $argv
    end
  '';
  nhSwitch = "nhs $argv";
  updateFirefoxCustomAddons = "update-firefox-addons ${deployment.localFlakePath}";
  nhsu = ''
    pushd ${deployment.localFlakePath}
    or return $status
    if ${if inhibitSleep then "true" else "false"}
      ${systemdInhibit} --what=shutdown:sleep:idle --who=nhsu --why="Nix flake update" --mode=block nix flake update
    else
      nix flake update
    end
    set -l update_status $status

    if test $update_status -eq 0
      set -l max_passes 10
      for pass in (seq $max_passes)
        set -l before_state (sha256sum flake.nix flake.lock 2>/dev/null | string collect)
        if ${if inhibitSleep then "true" else "false"}
          ${systemdInhibit} --what=shutdown:sleep:idle --who=nhsu --why="Regenerate flake metadata" --mode=block nix run .#write-flake
        else
          nix run .#write-flake
        end
        set update_status $status
        if test $update_status -ne 0
          break
        end
        set -l after_state (sha256sum flake.nix flake.lock 2>/dev/null | string collect)
        if test "$before_state" = "$after_state"
          break
        end
        if test $pass -eq $max_passes
          echo "write-flake did not settle after $max_passes passes"
          set update_status 1
        end
      end
    end
    popd
    test $update_status -eq 0
    or return $update_status
    nhs $argv
  '';
  nhSwitchUpgrade = "nhsu $argv";
}
