{ config, options, lib, namespace, ... }: {
  options.${namespace}.networking.firewall = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NixOS firewall";
    };
  };

  config.networking.firewall = lib.mkIf config.${namespace}.networking.firewall.enable {
    enable = lib.mkDefault true;
    allowPing = lib.mkDefault false;
    allowedTCPPorts = lib.mkDefault [];
    allowedUDPPorts = lib.mkDefault [];
  };
}