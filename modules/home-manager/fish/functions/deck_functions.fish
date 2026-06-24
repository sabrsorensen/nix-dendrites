# Steam Deck status function

function deckStatus -d "Show Steam Deck system status"
    set -l host_name (prompt_hostname)
    if test -z "$host_name"
        set host_name (uname -n)
    end
    set -l cpu_temp (
        sensors 2>/dev/null | awk '
            /^acpitz-acpi-0$/ { in_acpitz = 1; next }
            /^[[:alnum:]_.:-]+$/ && $0 != "acpitz-acpi-0" { in_acpitz = 0 }
            in_acpitz && /temp1:/ { print $2; exit }
        '
    )
    if test -z "$cpu_temp"
        set cpu_temp (
            sensors 2>/dev/null | awk '
                /^k10temp-pci-/ { in_k10temp = 1; next }
                /^[[:alnum:]_.:-]+$/ && $1 !~ /^k10temp-pci-/ { in_k10temp = 0 }
                in_k10temp && /Tctl:/ { print $2; exit }
            '
        )
    end
    if test -z "$cpu_temp"
        set cpu_temp "N/A"
    end

    echo "🎮 Steam Deck Status ($host_name):"
    echo "Battery: $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "N/A")%"
    echo "CPU Temp: $cpu_temp"
    echo "GPU: $(lspci | grep VGA | cut -d: -f3)"
    echo "Disk: $(df -h /home | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
end

function deckLogs -d "Show recent system logs" -a lines
    if test -z "$lines"
        set lines 50
    end
    echo "📋 Recent system logs (last $lines lines):"
    sudo journalctl -n $lines --no-pager
end
