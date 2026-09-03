{ lib, mkDeckyPlugin }:
mkDeckyPlugin {
  pname = "decky-nexus";
  # decky-nexus's own package.json version, plus a local marker: this vendor
  # copy carries the not-yet-upstreamed No Man's Sky support added in
  # ../../../../../../../../../decky-nexus (see games.ts's "275850" entry).
  version = "1.2.2-nms";
  src = ./assets/vendor/decky-nexus;
  hash = "sha256-4R6z0nEXV9DWYR1Zj2vRNfR3U+coYuOoZ8rBxWem9DE=";
  buildMessage = "Building Nexus Mods (decky-nexus) frontend...";
  meta = with lib; {
    description = "Unofficial Nexus Mods browser/installer for Decky Loader (local build, with No Man's Sky support)";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
