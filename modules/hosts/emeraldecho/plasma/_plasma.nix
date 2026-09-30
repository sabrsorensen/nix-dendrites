{
  shortcuts = {
  };
  configFile = {
    # Single QWERTY layout on the Deck; the base's us/dvorak pair stays off.
    kxkbrc.Layout.Use = false;
    kscreenlockerrc.Daemon.RequirePassword = false;
    # Existing wallet name on this host; renaming would orphan its secrets.
    kwalletrc.Wallet."Default Wallet" = "Default";
    kwinrc.Xwayland.Scale = 0.85;
    kwinrc.Xwayland.XwaylandEisNoPromptApps = "steam";
  };
}
