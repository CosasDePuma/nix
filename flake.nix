{
  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        name = "cosasdepuma-nix"; namespace = "lab";
        title = "My own IaC (Infrastructure as Code) using NixOS";

        channels-config.allowUnfree = true;
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # a convenience flake wrapper
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    # disk partitioning to be used with `nixos-anywhere`
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}