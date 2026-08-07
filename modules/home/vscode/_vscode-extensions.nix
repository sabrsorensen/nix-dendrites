{
  baseThemePackage,
  cfg,
  pkgs,
  ...
}:
let
  mkExtensions =
    extensions:
    let
      marketplaceExtensions = builtins.filter builtins.isString extensions;
      explicitExtensions = builtins.filter (extension: !builtins.isString extension) extensions;
    in
    pkgs.nix4vscode.forVscodeVersion (baseThemePackage.vscodeVersion or baseThemePackage.version
    ) marketplaceExtensions
    ++ explicitExtensions;
  openVsxExtension =
    {
      publisher,
      name,
      version,
      sha256,
      url,
    }:
    pkgs.vscode-utils.buildVscodeExtension {
      inherit version;
      pname = "${publisher}-${name}";
      src = pkgs.fetchurl {
        inherit url sha256;
      };
      vscodeExtPublisher = publisher;
      vscodeExtName = name;
      vscodeExtUniqueId = "${publisher}.${name}";
    };
  vscodiumDevpodContainers = openVsxExtension {
    publisher = "3timeslazy";
    name = "vscodium-devpodcontainers";
    version = "0.0.18";
    sha256 = "156nv9xvdsbq4782d0lpg7pjm45zi36ga6d7prv2lb844jsbli22";
    url = "https://open-vsx.org/api/3timeslazy/vscodium-devpodcontainers/0.0.18/file/3timeslazy.vscodium-devpodcontainers-0.0.18.vsix";
  };
  openRemoteWsl = openVsxExtension {
    publisher = "jeanp413";
    name = "open-remote-wsl";
    version = "0.0.5";
    sha256 = "0md3fmchsk5948n748m7j1zmj3hqjxy1vwbbhyrfk8pp5j55s0pi";
    url = "https://open-vsx.org/api/jeanp413/open-remote-wsl/0.0.5/file/jeanp413.open-remote-wsl-0.0.5.vsix";
  };
  openRemoteSsh = openVsxExtension {
    publisher = "jeanp413";
    name = "open-remote-ssh";
    version = "0.1.2";
    sha256 = "10ankbl6gfbrgc5ghj5744g1n66cx1vpr9bbmkp1k89m9m40ahsc";
    url = "https://open-vsx.org/api/jeanp413/open-remote-ssh/0.1.2/file/jeanp413.open-remote-ssh-0.1.2.vsix";
  };
  remoteExtensions =
    if cfg.packageFlavor == "vscode" then
      [
        "ms-vscode.remote-explorer"
        "ms-vscode-remote.remote-containers"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.remote-ssh-edit"
        "ms-vscode-remote.remote-wsl"
      ]
    else
      [ "ms-vscode.remote-explorer" ]
      ++ [
        vscodiumDevpodContainers
        openRemoteSsh
        openRemoteWsl
      ];
  defaultExtensionIds = [
    "docker.docker"
    "esbenp.prettier-vscode"
    "evondev.indent-rainbow-palettes"
    "github.vscode-github-actions"
    "humao.rest-client"
    "jeff-hykin.better-nix-syntax"
    "LiemLB.nix-flakes"
    "ms-azuretools.vscode-containers"
    "oderwat.indent-rainbow"
    "redhat.vscode-yaml"
    "rimuruchan.vscode-fix-checksums-next"
    "sabrsorensen.party-owl-84"
    "sabrsorensen.synthwave-blues"
    "tomoki1207.pdf"
    "vscodevim.vim"
  ]
  ++ remoteExtensions;
  pythonExtensionIds = [
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-pylance"
  ];
  fishExtensionIds = [ "bmalehorn.vscode-fish" ];
  nixExtensionIds = [ "signageos.signageos-vscode-sops" ];
  stm32ExtensionIds = [
    "eclipse-cdt.memory-inspector"
    "eclipse-cdt.serial-monitor"
    "ms-vscode.cmake-tools"
    "platformio.platformio-ide"
    "stmicroelectronics.stm32-vscode-extension"
    "stmicroelectronics.stm32cube-ide-build-analyzer"
    "stmicroelectronics.stm32cube-ide-build-cmake"
    "stmicroelectronics.stm32cube-ide-bundles-manager"
    "stmicroelectronics.stm32cube-ide-clangd"
    "stmicroelectronics.stm32cube-ide-core"
    "stmicroelectronics.stm32cube-ide-debug-core"
    "stmicroelectronics.stm32cube-ide-debug-generic-gdbserver"
    "stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver"
    "stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver"
    "stmicroelectronics.stm32cube-ide-project-manager"
    "stmicroelectronics.stm32cube-ide-registers"
    "stmicroelectronics.stm32cube-ide-rtos"
  ];
  higiExtensionIds = [
    "openai.chatgpt"
    "snyk-security.snyk-vulnerability-scanner"
    "pulumi.pulumi-vscode-tools"
    "ms-mssql.mssql"
    "ms-ossdata.vscode-pgsql"
  ];
in
{
  inherit
    defaultExtensionIds
    fishExtensionIds
    higiExtensionIds
    mkExtensions
    nixExtensionIds
    pythonExtensionIds
    stm32ExtensionIds
    ;
  defaultExtensions = mkExtensions (defaultExtensionIds ++ pythonExtensionIds ++ fishExtensionIds);
  nixExtensions = mkExtensions (
    defaultExtensionIds ++ pythonExtensionIds ++ fishExtensionIds ++ nixExtensionIds
  );
  pythonExtensions = mkExtensions (defaultExtensionIds ++ pythonExtensionIds);
  stm32Extensions = mkExtensions (defaultExtensionIds ++ stm32ExtensionIds);
  higiExtensions = mkExtensions (
    higiExtensionIds ++ pythonExtensionIds ++ [ "github.vscode-github-actions" ] ++ defaultExtensionIds
  );
}
