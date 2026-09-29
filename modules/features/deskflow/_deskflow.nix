{ lib, pkgs }:
let
  # libportal >= 0.10 provides xdp_input_capture_session_get_restore_token, which
  # Deskflow needs to persist the Input Capture portal permission (server mode)
  # instead of prompting on every login. nixpkgs is still on 0.9.1
  # (NixOS/nixpkgs#548917), and Deskflow silently compiles the feature out
  # against it. Scoped to Deskflow's build so nothing else rebuilds.
  libportal = pkgs.libportal.overrideAttrs (_: rec {
    version = "0.11.0";
    src = pkgs.fetchFromGitHub {
      owner = "flatpak";
      repo = "libportal";
      tag = version;
      hash = "sha256-9p1YniRgPxHGaV8hRwIyYaIrXDcXboq3kKHZ6xrJn70=";
    };
    # The Qt 6.9 private-API patch is upstream as of 0.10.0.
    patches = [ ];
  });

  # Continuous build: the input-capture persistence fix (deskflow/deskflow#9415)
  # landed after v1.26.0. Pinned to the commit the `continuous` tag pointed at.
  deskflow = (pkgs.deskflow.override { inherit libportal; }).overrideAttrs (_: {
    version = "1.26.0-unstable-2026-09-29";
    src = pkgs.fetchFromGitHub {
      owner = "deskflow";
      repo = "deskflow";
      rev = "8cf0b71b448b94f4703b0a02f6c694f0cd68917a";
      hash = "sha256-6cXHIeBIeiEps9/gC2Pl5NrEiiXS0zY15Z5wnh/kbtg=";
    };
    # Layouts now come from libxkbregistry, so nixpkgs' evdev.xml path
    # substitution no longer has a target; keep only the os-release one.
    postPatch = ''
      substituteInPlace deploy/linux/deploy.cmake \
        --replace-fail 'message(FATAL_ERROR "Unable to read file /etc/os-release")' 'set(RELEASE_FILE_CONTENTS "")'
    '';
    # Upstream dropped the bin/legacytests binary nixpkgs' checkPhase runs.
    checkPhase = ''
      runHook preCheck
      export QT_QPA_PLATFORM=offscreen
      ctest --test-dir "src/unittests" --output-on-failure
      runHook postCheck
    '';
    # Upstream's install now ships the docs nixpkgs' postInstall copied.
    postInstall = "";
  });
in
{
  environment.systemPackages = [
    deskflow
  ];
  networking = {
    firewall = {
      allowedTCPPorts = [
        24800 # Deskflow
      ];
      allowedUDPPorts = [
        24800 # Deskflow
      ];
    };
  };
  services.xserver = {
    # Set US Qwerty as default for KDE Plasma (for Deskflow compatibility)
    xkb = {
      layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };
  };
}
