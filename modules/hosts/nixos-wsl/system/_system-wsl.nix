{
  lib,
  pkgs,
  username,
  ...
}:
let
  # Pin the stable Linux artifacts published by Atlassian's TWG CLI manifest.
  twgSources = {
    aarch64-linux = {
      url = "https://teamwork-graph.atlassian.com/cli/twg-linux-arm64-v1.2.8";
      sha256 = "425eaeb911f09510ea8fbaa0231e987387881d198efffe625ce41a005fca40f5";
    };
    x86_64-linux = {
      url = "https://teamwork-graph.atlassian.com/cli/twg-linux-x64-v1.2.8";
      sha256 = "2ce21df22797b6323be31e1cabc8fa1f772251d67136de315c2761628134781d";
    };
  };
  twgSource =
    twgSources.${pkgs.stdenv.hostPlatform.system}
      or (throw "TWG CLI has no artifact for ${pkgs.stdenv.hostPlatform.system}");
  twg = pkgs.stdenvNoCC.mkDerivation {
    pname = "twg-cli";
    version = "1.2.8";
    src = pkgs.fetchurl {
      inherit (twgSource) sha256 url;
    };

    dontUnpack = true;
    installPhase = ''
      install -Dm755 "$src" "$out/bin/twg"
    '';
    meta = {
      description = "Atlassian Teamwork Graph command-line interface";
      homepage = "https://teamwork-graph.atlassian.com/cli/install";
      mainProgram = "twg";
      platforms = lib.platforms.linux;
    };
  };
in
{
  wsl = {
    defaultUser = username;
    docker-desktop.enable = true;
  };

  programs.nix-ld.libraries = with pkgs; [
    icu
    libsecret
    openssl
    zlib
    stdenv.cc.cc.lib
  ];
  environment.systemPackages = with pkgs; [
    gnumake
    python3
    ripgrep
    sops
    ssh-to-age
    twg
    wget
  ];
  programs.fish.enable = true;
}
