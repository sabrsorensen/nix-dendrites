{ ... }:
{
  inhibitSleep = ''
    echo "🔒 Inhibiting sleep for: $argv"
    echo -ne "\033]0;$argv\007"
    systemd-inhibit --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who="$USER" --why=nixos-rebuild --mode=block $argv
  '';
  cleanGenerations = ''
    nix-collect-garbage -d
    or return $status
    sudo nix-collect-garbage -d
    or return $status
    sudo nix store gc
    or return $status
    sudo nix store optimise
    or return $status
    sudo /run/current-system/bin/switch-to-configuration boot
  '';
}
