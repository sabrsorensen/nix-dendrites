{ ... }:
{
  podmanSystem = "sudo podman $argv";
  pds = "podmanSystem";
  podmanSystemPs = "sudo podman ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
  podmanSystemPsAll = "sudo podman ps -a --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
  podmanUserPs = "podman ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
  podmanUserPsAll = "podman ps -a --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
  pps = "podmanSystemPs";
  ppsa = "podmanSystemPsAll";
  ppu = "podmanUserPs";
  ppua = "podmanUserPsAll";
  dps = "podmanSystemPsAll";
  podmanUnitName = ''
    set name $argv[1]
    if test -z "$name"
      return 1
    end
    if string match -q 'podman-*.service' -- "$name"
      echo "$name"
    else if string match -q '*.service' -- "$name"
      echo "podman-"(string replace -r '\\.service$' "" -- "$name")".service"
    else
      echo "podman-$name.service"
    end
  '';
  podmanContainerName = ''
    set unit (podmanUnitName $argv[1])
    or return 1
    string replace -r '^podman-(.*)\\.service$' '$1' -- "$unit"
  '';
  podmanServices = "systemctl list-units --type=service --all 'podman-*.service'";
  pcs = "podmanServices";
  podmanServiceStatus = ''
    for name in $argv
      set unit (podmanUnitName $name)
      or return 1
      sudo systemctl status $unit
    end
  '';
  podmanServiceLogs = ''
    for name in $argv
      set unit (podmanUnitName $name)
      or return 1
      sudo journalctl -u $unit -f
    end
  '';
  podmanServicePull = ''
    if test (count $argv) -eq 0
      echo "Usage: podmanServicePull <container|service> [...]"
      return 1
    end
    for name in $argv
      set container (podmanContainerName $name)
      or return 1
      set image (sudo podman inspect --format '{{.ImageName}}' $container 2>/dev/null)
      if test -z "$image"
        echo "No existing rootful container found for $name" >&2
        return 1
      end
      echo "Pulling $image"
      sudo podman pull $image
      or return $status
    end
  '';
  podmanServiceUp = ''
    if test (count $argv) -eq 0
      echo "Usage: podmanServiceUp <container|service> [...]"
      return 1
    end
    for name in $argv
      set unit (podmanUnitName $name)
      or return 1
      if sudo systemctl is-active --quiet $unit
        sudo systemctl restart $unit
      else
        sudo systemctl start $unit
      end
      or return $status
    end
  '';
  pcss = "podmanServiceStatus";
  pcsl = "podmanServiceLogs";
  pcp = "podmanServicePull";
  pcu = "podmanServiceUp";
  dcp = "podmanServicePull";
  dcu = "podmanServiceUp";
}
