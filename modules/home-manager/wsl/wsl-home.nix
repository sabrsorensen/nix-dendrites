{
  inputs,
  ...
}:
{
  flake.modules.homeManager."wsl-home" =
    {
      imports = [
        inputs.self.modules.homeManager."vscode-wsl"
      ];

      my.vscode = {
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
