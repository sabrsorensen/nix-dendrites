{
  # Keep niri off the failing Quadro P520 (see hardware/_hardware.nix). niri
  # otherwise opens it via nouveau as a secondary GPU; on quit the nouveau
  # channel teardown stalls (~30s, nvkm_runl_preempt_wait), which hangs
  # logout and shutdown. by-path keeps this stable across card/renderD
  # renumbering.
  debug.ignore-drm-device = "/dev/dri/by-path/pci-0000:6c:00.0-render";
}
