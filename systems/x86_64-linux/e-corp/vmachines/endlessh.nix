_: { config, ... }: {
  containers."endlessh" = {
    autoStart = true;                                 # Automatically start the container
    ephemeral = true;                                 # Ephemeral container, will not persist data
    privateNetwork = true;                            # Use a private network
    localAddress = "10.100.0.1";                      # Local address for the container
    hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
    forwardPorts = [{                                 # Forward ports from the host to the container
      hostPort = 22;
      containerPort = config.containers."endlessh".config.services.endlessh-go.port;
    }];
    config = {

      # ============================= Config =============================

      system.stateVersion = config.system.stateVersion;
      services.endlessh-go = {
        enable = true;                                # Enable the endlessh service
        listenAddress = "0.0.0.0";                    # Address to listen on
        port = 22;                                    # Port to listen on (ssh)
        openFirewall = true;                          # Open the firewall for the service
        extraOptions = [ "-geoip_supplier=ip-api" ];  # Enable Geohash
        prometheus = {
          enable = true;                              # Enable Prometheus metrics
          listenAddress = "0.0.0.0"; port = 2121;     # Address to listen on (prometheus)
        };
      };
      networking = {
        hostName = "endlessh";                        # Hostname for the container
        firewall.allowedTCPPorts = [ config.containers."endlessh".config.services.endlessh-go.prometheus.port ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = builtins.map (port: port.hostPort) config.containers."endlessh".forwardPorts;
}