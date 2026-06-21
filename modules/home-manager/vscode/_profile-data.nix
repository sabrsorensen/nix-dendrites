{
  config,
  pkgs,
}:
let
  gitHubExts = [ "github.vscode-github-actions" ];

  pulumiExts = [ "pulumi.pulumi-vscode-tools" ];

  pythonExts = [
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-pylance"
  ];

  cSharpExts = with pkgs.vscode-extensions; [
    ms-dotnettools.csharp
    ms-dotnettools.csdevkit
    ms-dotnettools.vscode-dotnet-runtime
    patcx.vscode-nuget-gallery
  ];

  sqlExts = [
    "ms-mssql.mssql"
    "ms-ossdata.vscode-pgsql"
  ];

  higiExts = [
    "openai.chatgpt"
    "snyk-security.snyk-vulnerability-scanner"
  ]
  ++ pulumiExts;

  dotnetSettings = {
    "dotnetAcquisitionExtension.sharedExistingDotnetPath" = "/run/current-system/sw/bin/dotnet";
    "dotnetAcquisitionExtension.allowInvalidPaths" = true;
  };

  higiSettings = {
    "extensions.verifySignature" = false;
    "snyk.advanced.cliPath" = "C:\\Users\\ssorensen\\AppData\\Local\\snyk\\vscode-cli\\snyk-win.exe";
    "snyk.securityAtInception.autoConfigureSnykMcpServer" = true;
    "snyk.securityAtInception.executionFrequency" = "On Code Generation";
  }
  // pkgs.lib.optionalAttrs config.my.vscode.higi.runCodexInWsl {
    "chatgpt.runCodexInWindowsSubsystemForLinux" = true;
  };

  pythonSettings = {
    "[python]"."editor.formatOnType" = true;
  };
in
{
  inherit
    cSharpExts
    dotnetSettings
    gitHubExts
    higiExts
    higiSettings
    pythonExts
    pythonSettings
    sqlExts
    ;
}
