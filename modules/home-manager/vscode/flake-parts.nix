{
  flake-file.inputs = {
    partyowl84-vscode-theme = {
      url = "github:sabrsorensen/partyowl84-vscode-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    synthwave-blues-vscode-theme = {
      url = "github:sabrsorensen/synthwave-blues-vscode-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    synthwave-84-vscode-theme = {
      url = "github:sabrsorensen/nix-synthwave-vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
