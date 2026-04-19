# Syncthing Host Type Classification System
#
# This module provides centralized logic for determining which Syncthing
# configuration approach to use based on host type.
#
# Current policy:
# - Servers: Use NixOS system service (always-on)
# - Desktops/Laptops: Use Home Manager user service (session-based)
# - Steam Deck: Use Home Manager user service (gaming mode compatible)
# - RPis: Syncthing disabled (not needed for service hosts)
# - WSL: Syncthing disabled (not needed for dev environments)

{ lib, ... }:

{
  flake.lib.syncthing = rec {
    # Host type classification for Syncthing configuration
    hostTypes = {
      # Server hosts that should use NixOS Syncthing service (always-on)
      servers = [
        "AtlasUponRaiden"
      ];

      # Laptop/desktop hosts that should use Home Manager Syncthing (user session)
      desktops = [
        "ZaphodBeeblebrox"
        "Kamino"
      ];

      # Steam Deck hosts that should use Home Manager Syncthing (gaming mode)
      steamdecks = [
        "EmeraldEcho"
      ];

      # RPi hosts - Syncthing disabled (not needed)
      rpis = [
        "Naboo"
        "Nevarro"
        "Coruscant"
        "Ferrix"
        "Nixpi"
      ];

      # WSL hosts - Syncthing disabled (not needed)
      wsl = [
        "nixos-wsl"
      ];
    };

    # Hosts that should use NixOS system service
    systemServiceHosts = hostTypes.servers;

    # Hosts that should use Home Manager user service
    userServiceHosts = hostTypes.desktops ++ hostTypes.steamdecks;

    # Helper functions for host classification
    isServerHost = hostName: builtins.elem hostName hostTypes.servers;
    isRpiHost = hostName: builtins.elem hostName hostTypes.rpis;
    isDesktopHost = hostName: builtins.elem hostName hostTypes.desktops;
    isSteamDeckHost = hostName: builtins.elem hostName hostTypes.steamdecks;
    isWSLHost = hostName: builtins.elem hostName hostTypes.wsl;

    # Primary classification functions
    shouldUseSystemService = hostName: builtins.elem hostName systemServiceHosts;
    shouldUseUserService = hostName: builtins.elem hostName userServiceHosts;

    # UI/UX behavior classification
    shouldHaveTray = hostName: isDesktopHost hostName;
    isHeadless = hostName: isServerHost hostName || isRpiHost hostName;

    # Enabled/disabled state classification
    shouldEnableSyncthing = hostName: shouldUseSystemService hostName || shouldUseUserService hostName;
  };
}