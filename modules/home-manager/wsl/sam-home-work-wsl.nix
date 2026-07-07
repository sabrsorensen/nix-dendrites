{
  inputs,
  ...
}:
{
  flake.modules.homeManager."sam-home-work-wsl" =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [
        inputs.self.modules.homeManager."vscode-wsl"
      ];

      config = lib.mkIf config.my.host.is.wsl {
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
    };
}
