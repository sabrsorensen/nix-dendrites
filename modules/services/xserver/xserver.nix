{
  flake.modules.nixos.xserver = {
    services.xserver = {
      enable = true;
      videoDrivers = [ "nvidia" "intel" "modesetting" ];
      # Set US Qwerty as default for KDE Plasma (for Deskflow compatibility)
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
}