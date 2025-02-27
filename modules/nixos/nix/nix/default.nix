{ config, options, lib, namespace, ... }: {
  options.${namespace}.nix.gc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Nix garbage collection.";
    };
  };

  config = {
    boot.readOnlyNixStore = lib.mkForce true;
    nix.enable = lib.mkForce true;
    nix.gc = lib.mkIf config.${namespace}.nix.gc.enable {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
      persistent = lib.mkDefault true;
    };
  };
}