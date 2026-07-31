{
  config,
  lib,
  ...
}:
{
  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "sd_mod"
      "sdhci_pci"
      "sr_mod"
      "usbhid"
      "usb_storage"
      "xhci_pci"
    ];
    kernelModules = [ "kvm-amd" ];
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 2;
      consoleMode = "5";
    };
  };
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  services.pipewire.wireplumber.extraConfig."10-steamdeck-audio-names"."monitor.alsa.rules" = [
    {
      matches = [ { "device.nick" = "sof-nau8821-max"; } ];
      actions.update-props = {
        "device.product.name" = "Steam Deck Audio";
        "device.description" = "Steam Deck Audio";
      };
    }
  ];
}
