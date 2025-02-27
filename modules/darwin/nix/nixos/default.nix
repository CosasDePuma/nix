{ config, options, lib, namespace, ... }: {
  options.${namespace}.nixos = {
    version = lib.mkOption {
      type = lib.types.int;
      default = "25.05";
      description = "NixOS version.";
    };
  };

  config.system.stateVersion = lib.mkDefault config.${namespace}.nixos.version;
}