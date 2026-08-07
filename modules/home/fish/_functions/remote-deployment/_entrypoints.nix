{
  deployment,
  inhibitSleep,
  systemdInhibit,
  ...
}:
{
  nhsr = ''
    if string match -q '*@*' $argv[1]
      homeManagerSwitchRemote $argv
    else
      switch (remoteDeployMethod $argv[1])
        case secure
          secure-deploy $argv
        case build-then-switch
          nhBuildThenSwitchRemote $argv
        case '*'
          nhSwitchRemote $argv
      end
    end
  '';
  nhsur = ''
    if string match -q '*@*' $argv[1]
      echo "Home Manager remote activation uses the current flake state; no separate --update mode is applied."
      homeManagerSwitchRemote $argv
    else
      switch (remoteDeployMethod $argv[1])
        case secure
          secure-deploy --upgrade $argv
        case build-then-switch
          nhBuildThenSwitchUpgradeRemote $argv
        case '*'
          nhSwitchUpgradeRemote $argv
      end
    end
  '';
  nhsur_unsafe = ''
    if test (count $argv) -lt 1
      echo "Usage: nhsur_unsafe <configuration> [nh arguments...]"
      return 2
    end
    set -l target $argv[1]
    set -l target_lower (string lower $target)
    if ${if inhibitSleep then "true" else "false"}
      ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who=nhsur_unsafe --why="NixOS remote deployment" --mode=block nh os switch ${deployment.localFlakePath} -H $target_lower --target-host "nix-$target_lower" --update --keep-going $argv[2..-1]
    else
      nh os switch ${deployment.localFlakePath} -H $target_lower --target-host "nix-$target_lower" --update --keep-going $argv[2..-1]
    end
  '';
}
