{
  inputs,
  ...
}:
{
  flake.modules.homeManager."sam-home-work-wsl" = {
    imports = [
      inputs.self.modules.homeManager."vscode-wsl"
    ];

    my.editor = {
      packageFlavor = "vscode";
      installLocalDotnetSdk = false;
      higi.runCodexInWsl = true;
      profiles = {
        python = false;
        stm32 = false;
      };
      windowsInterop.enable = true;
    };

    my.git.signingKeyVariant = "wsl";
  };
}
