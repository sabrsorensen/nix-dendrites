# STM32CubeIDE is shipped prebuilt against one exact Eclipse release, so it
# needs the SWT native libraries from that same release rather than whatever
# nixpkgs' swt is on. 2.2.0 bundles Eclipse 4.38 (platform build
# v20251201-0920, SWT 3.132.0). Bump fullVersion and the hash together with
# the IDE whenever its plugins/org.eclipse.platform_* version moves.
{ swt }:
swt.overrideAttrs (old: {
  fullVersion = "R-4.38-202512010920";
  passthru = old.passthru // {
    srcMetadataByPlatform = {
      x86_64-linux = {
        platform = "gtk-linux-x86_64";
        hash = "sha256-XR3BfYlnF4/ZAVc1awoJwOVnVNf6bYMmedMsPYdcYnU=";
      };
    };
  };
})
