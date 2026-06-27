{
  inputs,
  ...
}:
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
      cfg = config.my.editor;
      enableVscode = config.my.host.is.wsl || config.my.host.is.laptop || config.my.host.is.desktop;
      vscodePackageConfig = import ./_package.nix {
        inherit
          config
          inputs
          lib
          pkgs
          ;
      };
      vscodeData = import ./_config-data.nix {
        inherit
          config
          inventory
          lib
          pkgs
          ;
        selectedTheme = vscodePackageConfig.selectedTheme;
        vscodePackage = vscodePackageConfig.package;
      };
      editorProgramConfig = {
        enable = true;
        #mutableExtsDir = true; # mutually exclusive with profiles
        #package = lib.mkDefault (pkgs.vscodium.fhsWithPackages (_: [ patched-openssh ]);
        # To use a different themed setup, set:
        package = vscodePackageConfig.package;
        profiles = {
          default = {
            enableExtensionUpdateCheck = true;
            enableUpdateCheck = true;
            keybindings = vscodeData.defaultKeyBindings ++ [ ];
            globalSnippets = { };
            languageSnippets = { };
            userSettings =
              vscodeData.defaultProfileOnlySettings
              // vscodeData.defaultUserSettings
              // lib.optionalAttrs cfg.windowsInterop.enable vscodeData.windowsTerminalSettings;
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
            if cfg.profiles.higiLlp then
              {
                extensions = vscodeData.mkExtensions (
                  vscodeData.higiExts
                  ++ vscodeData.pythonExts
                  ++ vscodeData.sqlExts
                  ++ vscodeData.gitHubExts
                  ++ vscodeData.defaultExts
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
            userSettings = vscodeData.pythonSettings // vscodeData.defaultUserSettings;
            enableMcpIntegration = true;
          };

          Python =
            if cfg.profiles.python then
              {
                extensions = vscodeData.mkExtensions (vscodeData.defaultExts ++ vscodeData.pythonExts);
                keybindings = vscodeData.defaultKeyBindings ++ [ ];
                languageSnippets = { };
                userSettings = vscodeData.pythonSettings // vscodeData.defaultUserSettings;
                enableMcpIntegration = true;
              }
            else
              { };
          STM32 =
            if cfg.profiles.stm32 then
              {
                extensions = vscodeData.mkExtensions (
                  vscodeData.defaultExts
                  ++ [
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
                  ]
                );
                keybindings = vscodeData.defaultKeyBindings ++ [ ];
                languageSnippets = { };
                userSettings = vscodeData.defaultUserSettings // {
                  "stm32cube-ide-core.configuration.productSTM32CubeMX.executablePath" =
                    "/etc/profiles/per-user/sam/bin/stm32cubemx";
                  "stm32cube-ide-core.enableTelemetry" = false;
                };
              }
            else
              { };
        };
      };
    in
    {
      options.my.editor = {
        packageFlavor = lib.mkOption {
          type = lib.types.enum [
            "vscode"
            "vscodium"
          ];
          default = "vscodium";
          description = "Which baked editor package family to use for Home Manager editor profiles.";
        };

        installLocalDotnetSdk = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to install a local .NET SDK alongside the configured editor environment.";
        };

        profiles = {
          higiLlp = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to expose the Higi LLP editor profile.";
          };

          python = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to expose the Python editor profile.";
          };

          stm32 = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to expose the STM32 editor profile.";
          };
        };

        higi.runCodexInWsl = lib.mkEnableOption "Run Codex from inside WSL for the Higi LLP profile";

        windowsInterop.enable = lib.mkEnableOption "Windows terminal integration for editor profiles";
      };

      config = lib.mkIf enableVscode ({
        home.packages = lib.optionals config.my.editor.installLocalDotnetSdk [
          pkgs.dotnetCorePackages.sdk_10_0-bin
        ];
        programs.vscode = lib.mkIf (cfg.packageFlavor == "vscode") editorProgramConfig;
        programs.vscodium = lib.mkIf (cfg.packageFlavor == "vscodium") editorProgramConfig;
      });
    };
}
