{
  flake.modules.homeManager.vscode =
    {
      config,
      inventory ? { },
      lib,
      pkgs,
      ...
    }:
    let
      vscodePackageConfig = import ./_package.nix {
        inherit config lib pkgs;
      };
      vscodeData = import ./_config-data.nix {
        inherit
          config
          inventory
          lib
          pkgs
          ;
        selectedBakedTheme = vscodePackageConfig.selectedBakedTheme;
        vscodePackage = vscodePackageConfig.package;
      };
    in
    {
      options.my.vscode = {
        installLocalDotnetSdk = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to install a local .NET SDK alongside the configured VS Code environment.";
        };

        profiles = {
          higiLlp = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to expose the Higi LLP VS Code profile.";
          };

          python = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to expose the Python VS Code profile.";
          };

          stm32 = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to expose the STM32 VS Code profile.";
          };
        };

        higi.runCodexInWsl = lib.mkEnableOption "Run Codex from inside WSL for the Higi LLP profile";

        windowsInterop.enable = lib.mkEnableOption "Windows terminal integration for VS Code profiles";
      };

      config.home.packages = lib.optionals config.my.vscode.installLocalDotnetSdk [
        pkgs.dotnetCorePackages.sdk_10_0-bin
      ];
      config.programs.vscode = {
        enable = true;
        #mutableExtsDir = true; # mutually exclusive with profiles
        #package = lib.mkDefault (pkgs.vscode.fhsWithPackages (_: [ patched-openssh ]);
        # To use a different baked version, set:
        package = vscodePackageConfig.package;
        #package = bakedVscodeByName "synthwave-blues";
        profiles = {
          default = {
            enableExtensionUpdateCheck = true;
            enableUpdateCheck = true;
            keybindings = vscodeData.defaultKeyBindings ++ [
            ];
            globalSnippets = {
            };
            languageSnippets = {
            };
            userSettings =
              vscodeData.defaultProfileOnlySettings
              // vscodeData.defaultUserSettings
              // lib.optionalAttrs config.my.vscode.windowsInterop.enable vscodeData.windowsTerminalSettings;
            extensions = vscodeData.mkExtensions (
              vscodeData.defaultExts
              ++ vscodeData.pythonExts
              ++ [
                "bmalehorn.vscode-fish"
              ]
            );
            enableMcpIntegration = true;
          };
          Higi_LLP =
            if config.my.vscode.profiles.higiLlp then
              {
                extensions = vscodeData.mkExtensions (
                  vscodeData.higiExts
                  ++ vscodeData.pythonExts
                  ++ vscodeData.sqlExts
                  ++ vscodeData.gitHubExts
                  ++ vscodeData.defaultExts
                  ++ [
                  ]
                );
                keybindings = vscodeData.defaultKeyBindings ++ [ ];
                languageSnippets = { };
                userSettings = vscodeData.defaultUserSettings // vscodeData.higiSettings // { };
                enableMcpIntegration = true;
              }
            else
              { };
          Nix = {
            extensions = vscodeData.mkExtensions (
              vscodeData.defaultExts
              ++ vscodeData.pythonExts
              ++ [
                "bmalehorn.vscode-fish"
                "signageos.signageos-vscode-sops"
              ]
            );
            keybindings = vscodeData.defaultKeyBindings ++ [ ];
            languageSnippets = {
              nix = {
                buildFirefoxXpiAddon = {
                  prefix = [
                    "buildFirefoxXpiAddon"
                    "ffXpi"
                  ];
                  description = "Nix expression for building a Firefox XPI addon";
                  body = [
                    "= buildFirefoxXpiAddon {"
                    "\tpname = \"$1\";"
                    "\tversion = \"$2\";"
                    "\taddonId = \"$3\";"
                    "\turl = \"$4\";"
                    "\tsha256 = \"\";"
                    "\tmeta = with lib;"
                    "\t{"
                    "\t\thomepage = \"$5\";"
                    "\t\tdescription = \"$6\";"
                    "\t\tlicense = \"$7\";"
                    "\t\tmozPermissions = [$8];"
                    "\t\tplatforms = platforms.all;"
                    "\t};"
                    "};"
                  ];
                };
              };
              json = {
                DhcpReservation = {
                  prefix = [ "reservation" ];
                  description = "Kea/CoreDNS DHCP reservation";
                  body = [
                    "{"
                    "  \"ip\": \"192.168.1.$0\","
                    "  \"hostname\": \"$2\","
                    "  \"mac\": \"$1\""
                    "}"
                  ];
                };
              };
            };
            userSettings =
              vscodeData.nixSettings // vscodeData.pythonSettings // vscodeData.defaultUserSettings;
            enableMcpIntegration = true;
          };

          Python =
            if config.my.vscode.profiles.python then
              {
                extensions = vscodeData.mkExtensions (
                  vscodeData.defaultExts
                  ++ vscodeData.pythonExts
                  ++ [
                  ]
                );
                keybindings = vscodeData.defaultKeyBindings ++ [ ];
                languageSnippets = { };
                userSettings = vscodeData.pythonSettings // vscodeData.defaultUserSettings;
                enableMcpIntegration = true;
              }
            else
              { };
          STM32 =
            if config.my.vscode.profiles.stm32 then
              {
                extensions = vscodeData.mkExtensions (
                  vscodeData.defaultExts
                  ++ [
                    "eclipse-cdt.memory-inspector"
                    "eclipse-cdt.serial-monitor"
                    "ms-vscode.cmake-tools"
                    "ms-vscode.cpptools"
                    "ms-vscode.cpptools-extension-pack"
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
                  ]
                );
                keybindings = vscodeData.defaultKeyBindings ++ [ ];
                languageSnippets = { };
                userSettings = vscodeData.defaultUserSettings;
              }
            else
              { };
        };
      };
    };
}
