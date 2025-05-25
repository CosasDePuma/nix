{
  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        meta.name = "cosasdepuma-nix"; namespace = "homelab";
        meta.title = "My own IaC (Infrastructure as Code) using NixOS";

        channels-config.allowUnfree = true;
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    # secret management
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # macOS support
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # disk partitioning to be used with `nixos-anywhere`
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # impermanence filesystem
    impermanence.url = "github:nix-community/impermanence";

    # a convenience flake wrapper
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
  };
}