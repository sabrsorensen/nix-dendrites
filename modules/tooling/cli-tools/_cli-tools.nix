{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  hasLocalFlake = config.my.deployment.localFlakePath != null;
  hasLocalGuiFlake = hasLocalFlake && config.my.host.features.localGuiTools;
  leasesEditor = inputs.self.packages.${system}.leases-editor;
in
{
  environment.systemPackages = [
    pkgs.git
    pkgs.tmux
    pkgs.home-manager
    pkgs.cowsay
    pkgs.asciiquarium
    pkgs.comma
    pkgs.p7zip
    pkgs.rclone
    pkgs.dig.dnsutils
    pkgs.htop
    pkgs.openssl
    pkgs.pciutils.out
    pkgs.ps
    pkgs.python3
    pkgs.ripgrep
    pkgs.uv
    pkgs.vim
    pkgs.wget
    pkgs.lshw
    pkgs.parted
  ]
  ++ lib.optionals hasLocalFlake [
    pkgs.just
    inputs.self.formatter.${system}
    inputs.self.packages.${system}.write-flake
    inputs.self.packages.${system}.write-inputs
    inputs.self.packages.${system}.write-lock
    inputs.self.packages.${system}.update-firefox-addons
    inputs.nix-auto-follow.packages.${system}.default
    pkgs.nurl
    pkgs.nix-init
  ]
  ++ lib.optionals hasLocalGuiFlake [ leasesEditor ]
  ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ pkgs.intel-gpu-tools ];
}
