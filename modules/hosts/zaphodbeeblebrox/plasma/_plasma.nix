# Zaphod-only Plasma settings and keys whose value differs from the shared
# base (modules/home/plasma/_plasma.nix). Imported by ../plasma.nix as a bare
# programs.plasma attrset; merged over the base by the module system.
{
  shortcuts = {
  };
  configFile = {
    kcminputrc."Libinput/1267/11299/ELAN9009:00 04F3:2C23".Enabled = false;
    kcminputrc."Libinput/1267/11350/ELAN9008:00 04F3:2C56".Enabled = false;
    kcminputrc."Libinput/1267/12545/ASUE1406:00 04F3:3101 Touchpad".Enabled = true;
    kcminputrc."Libinput/1267/12545/ASUE1406:00 04F3:3101 Touchpad".NaturalScroll = true;
    kxkbrc.Layout.VariantList = ",dvorak";
  };
}
