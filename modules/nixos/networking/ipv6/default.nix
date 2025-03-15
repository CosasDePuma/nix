{ config, options, lib, namespace, ... }: {
  options."${namespace}".networking = {
    ipv6Support = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable IPv6 support";
    };
  };

  config.networking = {
    enableIPv6 = lib.mkDefault config."${namespace}".networking.ipv6Support;
    dhcpcd.IPv6rs = lib.mkDefault config."${namespace}".networking.ipv6Support;
  };
}