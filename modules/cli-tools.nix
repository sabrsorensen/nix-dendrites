{ inputs, ... }:
{
  flake.modules.nixos.cli-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      hasLocalFlake = config.my.deployment.localFlakePath != null;
      hasLocalGuiFlake = hasLocalFlake && config.my.host.features.gui;
      qtPluginPath = lib.concatStringsSep ":" [
        "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}"
        "${pkgs.qt5.qtwayland}/${pkgs.qt5.qtbase.qtPluginPrefix}"
      ];
      qtQmlPath = lib.concatStringsSep ":" [
        "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtQmlPrefix}"
        "${pkgs.qt5.qtwayland}/${pkgs.qt5.qtbase.qtQmlPrefix}"
      ];
      leasesEditorPython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pyqt5 ]);
      leasesEditor = pkgs.writeShellApplication {
        name = "leases_editor.py";
        runtimeInputs = [
          leasesEditorPython
          pkgs.qt5.qtbase
          pkgs.qt5.qtwayland
        ];
        text = ''
          export QT_PLUGIN_PATH=${lib.escapeShellArg qtPluginPath}
          export QML2_IMPORT_PATH=${lib.escapeShellArg qtQmlPath}
          exec ${leasesEditorPython}/bin/python ${./assets/leases_editor.py} "$@"
        '';
      };
    in
    {
      environment.systemPackages = [
        pkgs.git
        pkgs.just
        pkgs.tmux
        pkgs.home-manager
        pkgs.cowsay
        pkgs.p7zip
        pkgs.rclone
        pkgs.dig.dnsutils
        pkgs.htop
        pkgs.openssl
        pkgs.pciutils.out
        # `ps` provides the expected command-line interface without pulling in
        # the broader `procps` package attribute.
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
        # Local checkouts need formatting and flake-maintenance tools.
        inputs.self.formatter.${system}
        inputs.self.packages.${system}.write-flake
        inputs.self.packages.${system}.write-inputs
        inputs.self.packages.${system}.write-lock
        inputs.self.packages.${system}.update-firefox-addons
        inputs.nix-auto-follow.packages.${system}.default
      ]
      ++ lib.optionals hasLocalGuiFlake [ leasesEditor ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ pkgs.intel-gpu-tools ];
    };
}
