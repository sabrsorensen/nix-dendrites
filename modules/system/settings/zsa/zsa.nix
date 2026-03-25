{
  lib,
  pkgs,
  ...
}:
{
  flake.modules.nixos.zsa = {
    # Enable ZSA keyboard support
    hardware.keyboard.zsa.enable = true;
    environment.systemPackages = with pkgs; [
      keymapp
    ];
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "keymapp"
    ];
  };
}