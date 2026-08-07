{ ... }:
{
  piStatus = ''
    echo "🥧 Pi System Status ("(hostname)"):"
    echo "Uptime: "(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    echo "Load: "(cat /proc/loadavg | cut -d' ' -f1-3)
    echo "Memory: "(free -b | awk '/^Mem:/ {printf "%.1fGi/%.1fGi (%.0f%%)", $3/1024/1024/1024, $2/1024/1024/1024, ($3/$2)*100}')
    echo "Disk: "(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')

    set -l temp_found false
    for zone in /sys/class/thermal/thermal_zone*/temp
      if test -r "$zone"
        set -l temp_millidegrees (cat "$zone" 2>/dev/null)
        if test -n "$temp_millidegrees"; and test "$temp_millidegrees" -gt 0
          echo "Temperature: "(math "$temp_millidegrees / 1000")"°C"
          set temp_found true
          break
        end
      end
    end

    if test "$temp_found" = false; and command -sq vcgencmd
      set -l temp (sudo vcgencmd measure_temp 2>/dev/null | cut -d= -f2)
      if test -n "$temp"
        echo "Temperature: $temp"
        set temp_found true
      end
    end

    if test "$temp_found" = false
      echo "Temperature: N/A"
    end

    if systemctl list-unit-files blocky.service >/dev/null 2>&1
      if systemctl is-active --quiet blocky
        echo "Blocky: ✅ Running"
      else
        echo "Blocky: ❌ Not running"
      end
    end

    if systemctl list-unit-files netbird-management.service >/dev/null 2>&1
      if systemctl is-active --quiet netbird-management
        echo "Netbird Management: ✅ Running"
      else
        echo "Netbird Management: ❌ Not running"
      end
    end
  '';
  piLogs = ''
    set -l lines 50
    if test (count $argv) -gt 0
      set lines $argv[1]
    end
    echo "📋 Recent system logs (last $lines lines):"
    sudo journalctl -n "$lines" --no-pager
  '';
}
