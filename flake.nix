{
  description = "My own IaC (Infrastructure as Code) using Nix";

  outputs =
    { self, ... }@inputs:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      lib' = import ./lib.nix (inputs // { inherit (inputs.nixpkgs) lib; });
      inherit (lib') import' forEachSystem;
    in
    {
      # +------------- development shells -------------+

      devShells = forEachSystem systems (
        { pkgs, system }@args:
        {
          default = self.devShells.${system}.nixos;
          nixos = import ./shells/nixos.nix args;
        }
      );

      # +----------------- formatter ------------------+

      formatter = forEachSystem systems (
        { system, ... }: inputs.nixpkgs.legacyPackages."${system}".nixfmt-tree
      );

      # +----------------- libraries ------------------+

      lib = lib';

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

    # user-defined configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
