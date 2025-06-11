{
  description = "My own IaC (Infrastructure as Code) using Nix";

  outputs =
    { self, ... }@inputs:
    let
      inherit (inputs.nixpkgs) lib;
      lib' = import ./lib.nix (inputs // lib);
      inherit (lib') forEachSystem;
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      extraArgs = {
        inherit inputs lib;
        stateVersion = "25.05";
      };
    in
    {
      # +--------------- darwin systems ---------------+

      darwinConfigurations = {
        airbender = import ./systems/aarch64-darwin/airbender extraArgs;
      };

      # +------------- development shells -------------+

      devShells = forEachSystem systems (
        { system, ... }@args:
        {
          default = self.devShells.${system}.nixos;
          nixos = import ./shells/nixos.nix (args // extraArgs);
          hacking = import ./shells/hacking.nix (args // extraArgs);
        }
      );

      # +----------------- formatter ------------------+

      formatter = forEachSystem systems (
        { system, ... }: inputs.nixpkgs.legacyPackages."${system}".nixfmt-tree
      );

      # +----------------- libraries ------------------+

      lib = lib';

      # +--------------- nixos systems ----------------+

      nixosConfigurations = {
        wonderland = import ./systems/x86_64-linux/wonderland extraArgs;
      };

      # +----------------- templates ------------------+

      templates = {
        shell = {
          path = ./templates/shell;
          description = "Shell template for development environments";
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # secret management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS support
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disk partitioning to be used with `nixos-anywhere`
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # user-defined configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix darwin support
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
