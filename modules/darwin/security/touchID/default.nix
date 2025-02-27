{ config, options, lib, namespace, ... }: {
  options.${namespace}.security.touchID = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Touch ID as main security method";
    };
  };

  config.security.pam.services.sudo_local.touchIdAuth = lib.mkDefault config.${namespace}.security.touchID.enable;
}