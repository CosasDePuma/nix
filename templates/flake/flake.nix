{
  description = "❄️ My new flake!";

  outputs =
    inputs:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      lib' = import ./lib.nix (inputs // { inherit (inputs.nixpkgs) lib; });
      inherit (lib') forEachSystem;
    in
    {
      # +------------- development shells -------------+

      devShells = forEachSystem systems (args: {
        default = import ./shells/default.nix args;
      });

      # +----------------- formatter ------------------+

      formatter = forEachSystem systems (
        { system, ... }: inputs.nixpkgs.legacyPackages."${system}".nixfmt-tree
      );

      # +----------------- libraries ------------------+

      lib = lib';

      # +----------------- templates ------------------+

      templates = { };
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
