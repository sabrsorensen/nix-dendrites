# Fish shell greeting function

function fish_greeting -d "Custom fish shell greeting"
    # Show Pi status on Pi hosts first
    if functions -q piStatus
        piStatus
        echo ""
        echo "💡 Run 'piStatus' for updated info or 'piLogs [lines]' for system logs"
        echo ""
    end

    if functions -q deckStatus
        deckStatus
        echo ""
        echo "💡 Run 'deckStatus' for updated info or 'deckLogs [lines]' for system logs"
        echo ""
    end

    if not which fortune >/dev/null
        echo "Install fortune"
    end
    if not which cowsay >/dev/null
        echo "Install cowsay"
    end
    if not which lolcat >/dev/null
        echo "Install lolcat"
    end

    set -l toon (random choice {default,bud-frogs,dragon,dragon-and-cow,elephant,moose,stegosaurus,tux,vader})
    if which lolcat >/dev/null
        fortune -s | cowsay -f $toon | lolcat
    else if which fortune >/dev/null
        fortune -s | cowsay -f $toon
    else
        echo "Something fishy going on around here ..."
    end
end
