_: { config, ... }: {
  networking.nat = {
    enable = true;                     # Enable NAT
    enableIPv6 = false;                # Disable IPv6 NAT
    internalInterfaces = [ "ve-+" ];   # Internal interfaces used by containers
    externalInterface = builtins.head (builtins.attrNames config.networking.interfaces);
  };
}