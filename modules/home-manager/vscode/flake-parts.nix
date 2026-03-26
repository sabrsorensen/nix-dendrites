{
  flake-file.inputs = {
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
