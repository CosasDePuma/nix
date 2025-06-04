_: { config, ... }: {
  networking = {

    # =============================== DNS ================================

    nameservers = [ "1.1.1.1" "8.8.8.8" ];   # DNS servers

    # ============================= Firewall =============================

    firewall = {
      enable = true;                         # Enable the firewall
      allowPing = false;                     # Disable ping responses
    };

    # ============================== Hosts ===============================
    
    hostName = "e-corp";                     # Hostname (used by flakes and some services)
    hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);

    # ============================ Interfaces ============================

    usePredictableInterfaceNames = false;    # Disable modern interface names
    interfaces."eth0".ipv4.addresses = [{    # Default interface name and static IPv4 address
      address = "51.159.16.208";
      prefixLength = 24;
    }];
    defaultGateway = {                       # Default gateway
      interface = "eth0";
      address = "51.159.16.1";
    };
  };
}