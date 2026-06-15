{
  nixosVariants = [
    {
      moduleName = "EmeraldEcho";
      outputName = "emeraldecho";
      bootMode = "dual";
      lifecycle = "system";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoDualBoot";
      outputName = "emeraldecho-dualboot";
      bootMode = "dual";
      lifecycle = "system";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoSingleBoot";
      outputName = "emeraldecho-singleboot";
      bootMode = "single";
      lifecycle = "system";
      buildProduct = "toplevel";
      includeInChecks = false;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoBootstrap";
      outputName = "emeraldecho-bootstrap";
      bootMode = "dual";
      lifecycle = "bootstrap";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoDualBootBootstrap";
      outputName = "emeraldecho-dualboot-bootstrap";
      bootMode = "dual";
      lifecycle = "bootstrap";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoSingleBootBootstrap";
      outputName = "emeraldecho-singleboot-bootstrap";
      bootMode = "single";
      lifecycle = "bootstrap";
      buildProduct = "toplevel";
      includeInChecks = false;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoInstaller";
      outputName = "emeraldecho-installer";
      bootMode = "dual";
      lifecycle = "installer";
      buildProduct = "isoImage";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoDualBootInstaller";
      outputName = "emeraldecho-dualboot-installer";
      bootMode = "dual";
      lifecycle = "installer";
      buildProduct = "isoImage";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      moduleName = "EmeraldEchoSingleBootInstaller";
      outputName = "emeraldecho-singleboot-installer";
      bootMode = "single";
      lifecycle = "installer";
      buildProduct = "isoImage";
      includeInChecks = false;
      includeInPackages = true;
    }
  ];
}
