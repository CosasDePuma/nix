{ config, options, lib, namespace, ... }: {
  options.${namespace}.networking = {
    ipv4 = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "dhcp";
      description = "The IPv4 address to use for the host. Can be 'dhcp' or an IPv4 address.";
    };
    gateway4 = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
      description = "The IPv4 address of the gateway to use for the host. If not specified, the gateway will be the first address (x.x.x.1).";
    };
  };

  config.networking = let
    isStatic = config.${namespace}.networking.ipv4 != "dhcp";
  in {
    # Interfaces
    usePredictableInterfaceNames = lib.mkDefault false;

    # Static IPv4 address
    interfaces."eth0".ipv4.addresses = lib.lists.optional isStatic {
      address = lib.mkDefault config.${namespace}.networking.ipv4;
      prefixLength = lib.mkDefault 24;
    };
    defaultGateway = lib.mkIf isStatic {
      address = lib.mkDefault (if config.${namespace}.networking.gateway4 == null
        then lib.concatStringsSep "." ((lib.take 3 (lib.splitString "." config.${namespace}.networking.ipv4)) ++ [ "1" ])
        else config.${namespace}.networking.gateway4);
      interface = lib.mkDefault "eth0";
    };

    # Dynamic IPv4 address
    networkmanager.enable = lib.mkDefault (!isStatic);
    useDHCP = lib.mkDefault (!isStatic); 
  };
}