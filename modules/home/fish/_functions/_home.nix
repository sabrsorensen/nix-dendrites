args@{
  canDeployRemotely,
  hasLocalNhs,
  hasPodman,
  host,
  isSteamDeck,
  lib,
  ...
}:
import ./_base.nix args
// lib.optionalAttrs host.is.rpi (import ./_rpi.nix args)
// lib.optionalAttrs isSteamDeck (import ./_steamdeck.nix args)
// import ./_local.nix args
// lib.optionalAttrs hasLocalNhs (import ./_local-checkout.nix args)
// lib.optionalAttrs canDeployRemotely (import ./_remote-deployment.nix args)
// lib.optionalAttrs hasPodman (import ./_podman.nix args)
