# Kamino-only Plasma settings and keys whose value differs from the shared
# base (modules/home/plasma/_plasma.nix). Imported by ../plasma.nix as a bare
# programs.plasma attrset; merged over the base by the module system.
{
  shortcuts = {
  };
  configFile = {
    kcminputrc."Libinput/1267/10848/ELAN2513:00 04F3:2A60".Enabled = false;
    kcminputrc."Libinput/1739/52745/SYNA30B4:00 06CB:CE09".NaturalScroll = true;
  };
}
