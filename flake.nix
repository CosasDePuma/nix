{
  outputs = { snowfall, ... } @ inputs:
    snowfall.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        name = "homelab"; namespace = "homelab";
        title = "My own IaC (Infrastructure as Code) using NixOS";

        channels-config.allowUnfree = true;
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # a convenience flake wrapper
    snowfall.url = "github:snowfallorg/lib";
    snowfall.inputs.nixpkgs.follows = "nixpkgs";

    # disk partitioning to be used with `nixos-anywhere`
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}
