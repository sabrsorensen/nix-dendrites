# Pi-specific status and monitoring functions

function piStatus -d "Show comprehensive Pi system status"
    echo "🥧 Pi System Status ("(hostname)"):"
    # Use compatible uptime command (no -p flag)
    echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
    echo "Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
    # Fix memory calculation with proper awk syntax
    echo "Memory: $(free -b | awk '/^Mem:/ {printf "%.1fGi/%.1fGi (%.0f%%)", $3/1024/1024/1024, $2/1024/1024/1024, ($3/$2)*100}')"
    echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"

    # Temperature detection with better fallbacks (matching MOTD script)
    set TEMP_FOUND false

    # Try thermal zones (multiple possibilities)
    for zone in /sys/class/thermal/thermal_zone*/temp
        if test -r "$zone"
            set TEMP_MILLIDEGREES (cat "$zone" 2>/dev/null)
            if test -n "$TEMP_MILLIDEGREES" && test "$TEMP_MILLIDEGREES" -gt 0
                set TEMP_CELSIUS (math "$TEMP_MILLIDEGREES / 1000")
                echo "Temperature: $TEMP_CELSIUS°C"
                set TEMP_FOUND true
                break
            end
        end
    end

    # Try vcgencmd with sudo if thermal zone failed
    if test "$TEMP_FOUND" = false && command -v vcgencmd >/dev/null 2>&1
        set TEMP (sudo vcgencmd measure_temp 2>/dev/null | cut -d= -f2)
        if test -n "$TEMP"
            echo "Temperature: $TEMP"
            set TEMP_FOUND true
        end
    end

    # Fallback if nothing worked
    if test "$TEMP_FOUND" = false
        echo "Temperature: N/A"
    end

    # Check services only if they exist
    if systemctl list-unit-files adguardhome.service >/dev/null 2>&1
        if systemctl is-active --quiet adguardhome
            echo "AdGuard: ✅ Running"
        else
            echo "AdGuard: ❌ Not running"
        end
    end

    if systemctl list-unit-files netbird-management.service >/dev/null 2>&1
        if systemctl is-active --quiet netbird-management
            echo "Netbird Management: ✅ Running"
        else
            echo "Netbird Management: ❌ Not running"
        end
    end
end

function piLogs -d "Show recent system logs" -a lines
    if test -z "$lines"
        set lines 50
    end
    echo "📋 Recent system logs (last $lines lines):"
    sudo journalctl -n $lines --no-pager
end
