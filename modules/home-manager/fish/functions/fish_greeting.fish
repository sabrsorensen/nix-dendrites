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

    if not command -sq fortune
        echo "Install fortune"
    end
    if not command -sq cowsay
        echo "Install cowsay"
    end
    if not command -sq lolcat
        echo "Install lolcat"
    end

    set -l toon (random choice {default,bud-frogs,dragon,dragon-and-cow,elephant,moose,stegosaurus,tux,vader})
    if command -sq lolcat
        fortune -s | cowsay -f $toon | lolcat
    else if command -sq fortune
        fortune -s | cowsay -f $toon
    else
        echo "Something fishy going on around here ..."
    end
end
