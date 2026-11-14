{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    installVimSyntax = true;
    settings = {
      # TODO: fill in Ghostty settings (see `ghostty +show-config --default --docs`).
      theme = "Night Owl";
      background-opacity = "0.95";
    };
  };
}
