{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Handle XRGaming udev rules through proper NixOS configuration
  services.udev.extraRules = lib.mkIf config.jovian.decky-loader.enable ''
    # XRGaming udev rules for various XR devices
    # Rayneo XR devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="3318", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="32e9", MODE="0664", GROUP="plugdev"

    # Rokid XR devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04e8", ATTRS{idProduct}=="a007", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="16d3", MODE="0664", GROUP="plugdev"

    # Viture XR devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="30a6", MODE="0664", GROUP="plugdev"

    # XREAL XR devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0486", ATTRS{idProduct}=="5740", MODE="0664", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0486", ATTRS{idProduct}=="5744", MODE="0664", GROUP="plugdev"

    # uinput device for XR driver
    KERNEL=="uinput", MODE="0664", GROUP="input"
  '';
}
