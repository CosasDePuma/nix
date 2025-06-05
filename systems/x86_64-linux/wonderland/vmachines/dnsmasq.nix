{ domain, ... }: { config, lib, ... }: {
  containers."dnsmasq" = {
    autoStart = true;                          # Automatically start the container
    ephemeral = true;                          # Ephemeral container, will not persist data
    privateNetwork = true;                     # Use a private network
    localAddress = "10.100.0.2";               # Local address for the container
    hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
    config = {

      # ============================= Config =============================

      system.stateVersion = config.system.stateVersion;
      services.dnsmasq = {
        enable = true;                         # Enable the dnsmasq service
        resolveLocalQueries = false;           # Disable local DNS resolution
        settings = {
          address = lib.optionals (config.containers ? "traefik") "/${domain}/${config.containers."traefik".localAddress}";
          bogus-priv = true;                   # Ignore private IP addresses
          bind-interfaces = true;              # Bind to the specified interfaces
          cache-size = 1000;                   # Cache size
          domain-needed = true;                # Ignore non-domain queries
          interface = [ "lo" "eth0" ];         # Interfaces to listen on
          min-cache-ttl = 300;                 # Minimum cache TTL
          no-resolv = true;                    # Disable DNS resolution using /etc/resolv.conf
          port = 53;                           # Port to listen on
          rebind-domain-ok = "|lan";           # Allow DNS rebinding for local domains
          server = [ "1.1.1.1" "8.8.8.8" ];    # DNS servers to use
          stop-dns-rebind = true;              # Disable DNS rebinding
          strict-order = true;                 # Use the specified DNS servers in order
        };
      };
      networking = {
        hostName = "dnsmasq";                  # Hostname for the container
        firewall = let                         # Open the fierewall
          ports = config.containers."dnsmasq".config.services.dnsmasq.settings.port;
        in {
          allowedTCPPorts = ports;
          allowedUDPPorts = ports;
        };
      };
    };
  };
}