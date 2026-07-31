args@{
  canDeployRemotely,
  hasLocalNhs,
  hasPodman,
  host,
  isSteamDeck,
  lib,
  ...
}:
import ./_base-content.nix args
// lib.optionalAttrs host.is.rpi (import ./_rpi-content.nix args)
// lib.optionalAttrs isSteamDeck (import ./_steamdeck-content.nix args)
// import ./_local-content.nix args
// lib.optionalAttrs hasLocalNhs (import ./_local-checkout-content.nix args)
// lib.optionalAttrs canDeployRemotely (import ./_remote-deployment-content.nix args)
// lib.optionalAttrs hasPodman (import ./_podman-content.nix args)
