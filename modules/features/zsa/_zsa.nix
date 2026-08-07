{ pkgs }:
{
  # Enable ZSA keyboard support
  hardware.keyboard.zsa.enable = true;
  environment.systemPackages = with pkgs; [
    keymapp
  ];
  my.unfreePackageNames = [ "keymapp" ];
}
