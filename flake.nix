{
  description = "My own IaC (Infrastructure as Code) using Nix";

  outputs =
    { self, ... }@inputs:
    let
      inherit (inputs.nixpkgs) lib;
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      extraArgs = {
        inherit inputs lib;
        stateVersion = "25.05";
      };
      forEachSystem =
        supportedSystems: fn:
        lib.genAttrs supportedSystems (
          system:
          fn {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );
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
          hacking-infra = import ./shells/hacking-infra.nix (args // extraArgs);
          nixos = import ./shells/nixos.nix (args // extraArgs);
        }
      );

      # +----------------- formatter ------------------+

      formatter = forEachSystem systems (
        { system, ... }: inputs.nixpkgs.legacyPackages."${system}".nixfmt-tree
      );

      # +--------------- nixos systems ----------------+

      nixosConfigurations = {
        wonderland = import ./systems/x86_64-linux/wonderland extraArgs;
      };

      # +----------------- templates ------------------+

      templates = {
        flake = {
          path = ./templates/flake;
          description = "Flake template";
        };
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
