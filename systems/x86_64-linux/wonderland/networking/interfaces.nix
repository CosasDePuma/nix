_: {
  networking = {
    usePredictableInterfaceNames = false;           # Disable modern interface names
    interfaces."eth0".ipv4.addresses = [{           # Default interface name and static IPv4 address
      address = "192.168.1.5";
      prefixLength = 24;
    }];
    defaultGateway = {                              # Default gateway
      interface = "eth0";
      address = "192.168.1.1";
    };
  };
}