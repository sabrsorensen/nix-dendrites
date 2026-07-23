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
        # Keep the predecessor's `ps` package rather than substituting the
        # broader `procps` attribute during the module reorganization.
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
        # The predecessor exposed the flake formatter in every local checkout
        # profile; it was lost when the CLI tools were reorganized.
        inputs.self.formatter.${system}
        inputs.self.packages.${system}.write-flake
        inputs.self.packages.${system}.write-inputs
        inputs.self.packages.${system}.write-lock
        inputs.self.packages.${system}.update-firefox-addons
      ]
      ++ lib.optionals hasLocalGuiFlake [ leasesEditor ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ pkgs.intel-gpu-tools ];
    };
}
