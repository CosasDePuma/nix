{ config, options, lib, namespace, ... }: {
  options.${namespace}.nixos = {
    version = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "25.05";
      description = "NixOS version.";
    };

    followFlake = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
      description = "Flake to automatically synchronize the system with.";
    };
  };

  config = {
    system.stateVersion = lib.mkDefault config.${namespace}.nixos.version;
    system.autoUpgrade = lib.mkIf (config.${namespace}.nixos.followFlake != null) {
      enable = lib.mkDefault true;
      flake = lib.mkDefault config.${namespace}.nixos.followFlake;
      dates = lib.mkDefault "daily";
      operation = lib.mkDefault "switch";
      persistent = lib.mkDefault true;
    };
  };
}