{ config, lib, ... }: {
  config = {
    nix.enable = lib.mkForce false;
    nix.extraOptions = lib.mkDefault "extra-platforms = x86_64-darwin aarch64-darwin";
    nix.settings.auto-optimise-store = lib.mkForce false;  # https://github.com/NixOS/nix/issues/7273
    nix.settings.experimental-features = lib.mkDefault [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = lib.mkDefault true;
  };
}