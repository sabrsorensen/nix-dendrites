{
  nixosVariants = [
    {
      name = "EmeraldEcho";
      outputName = "emeraldecho";
      bootMode = "dual";
      lifecycle = "system";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoDualBoot";
      outputName = "emeraldecho-dualboot";
      bootMode = "dual";
      lifecycle = "system";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoSingleBoot";
      outputName = "emeraldecho-singleboot";
      bootMode = "single";
      lifecycle = "system";
      buildProduct = "toplevel";
      includeInChecks = false;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoBootstrap";
      outputName = "emeraldecho-bootstrap";
      bootMode = "dual";
      lifecycle = "bootstrap";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoDualBootBootstrap";
      outputName = "emeraldecho-dualboot-bootstrap";
      bootMode = "dual";
      lifecycle = "bootstrap";
      buildProduct = "toplevel";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoSingleBootBootstrap";
      outputName = "emeraldecho-singleboot-bootstrap";
      bootMode = "single";
      lifecycle = "bootstrap";
      buildProduct = "toplevel";
      includeInChecks = false;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoInstaller";
      outputName = "emeraldecho-installer";
      bootMode = "dual";
      lifecycle = "installer";
      buildProduct = "isoImage";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoDualBootInstaller";
      outputName = "emeraldecho-dualboot-installer";
      bootMode = "dual";
      lifecycle = "installer";
      buildProduct = "isoImage";
      includeInChecks = true;
      includeInPackages = true;
    }
    {
      name = "EmeraldEchoSingleBootInstaller";
      outputName = "emeraldecho-singleboot-installer";
      bootMode = "single";
      lifecycle = "installer";
      buildProduct = "isoImage";
      includeInChecks = false;
      includeInPackages = true;
    }
  ];
}
