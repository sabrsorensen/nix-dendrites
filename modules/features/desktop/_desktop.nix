{ ... }:
{
  # Session-agnostic graphical desktop plumbing. The Plasma session itself
  # lives in features.plasma (modules/features/plasma), which this feature
  # defaults on.
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
  };
  services.geoclue2.enable = true;
  xdg.portal.enable = true;
}
