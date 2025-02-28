{ config, lib, ... }: {
  config = {
    boot.readOnlyNixStore = lib.mkForce true;
    nix.enable = lib.mkForce true;
    nix.settings.experimental-features = lib.mkDefault [ "nix-command" "flakes" ];
    nix.optimise.automatic = lib.mkDefault true;
    nix.optimise.dates = lib.mkDefault "daily";
    nix.optimise.persistent = lib.mkDefault true;
    nix.settings.auto-optimise-store = lib.mkDefault true;
    nix.gc.automatic = lib.mkDefault true;
    nix.gc.dates = lib.mkDefault "weekly";
    nix.gc.options = lib.mkDefault "--delete-older-than 7d";
    nix.gc.persistent = lib.mkDefault true;
    nixpkgs.config.allowUnfree = lib.mkDefault true;
  };
}