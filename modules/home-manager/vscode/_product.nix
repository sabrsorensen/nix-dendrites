{
  flavor ? "vscodium",
}:
let
  products = {
    vscode = {
      binaryName = "code";
      configDirName = "Code";
      stateDirName = "vscode";
      urlHandlerBinaryName = "code-url-handler";
      urlHandlerDesktopName = "code-url-handler.desktop";
      windowsCli = "code.cmd";
      windowsConfigDirName = "Code";
    };
    vscodium = {
      binaryName = "codium";
      configDirName = "VSCodium";
      stateDirName = "vscodium";
      urlHandlerBinaryName = "codium-url-handler";
      urlHandlerDesktopName = "codium-url-handler.desktop";
      windowsCli = "codium.cmd";
      windowsConfigDirName = "VSCodium";
    };
  };
in
products.${flavor} or products.vscodium
