let
  # Define desktop entry once for reuse
  returnToGamingEntry = {
    name = "Return to Gaming Mode";
    exec = "qdbus org.kde.Shutdown /Shutdown logout";
    icon = "steam";
    terminal = false;
    categories = [ "System" ];
    comment = "Logout and return to Steam";
  };
in
{

  # Desktop entry for both start menu and desktop
  xdg.desktopEntries.return-to-gaming = returnToGamingEntry;

  # Place the same desktop entry on the desktop
  home.file."Desktop/return-to-gaming.desktop".text = ''
    [Desktop Entry]
    Name=${returnToGamingEntry.name}
    Exec=${returnToGamingEntry.exec}
    Icon=${returnToGamingEntry.icon}
    Terminal=${if returnToGamingEntry.terminal then "true" else "false"}
    Type=Application
    Categories=${builtins.concatStringsSep ";" returnToGamingEntry.categories};
    Comment=${returnToGamingEntry.comment}
  '';

}
