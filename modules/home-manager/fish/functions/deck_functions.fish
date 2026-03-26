# Steam Deck status function

function deckStatus -d "Show Steam Deck system status"
    echo "🎮 Steam Deck Status ("(hostname)"):"
    echo "Battery: $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "N/A")%"
    echo "CPU Temp: $(sensors 2>/dev/null | grep 'Tctl:' | awk '{print $2}' || echo "N/A")"
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
