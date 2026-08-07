{ ... }:
{
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
