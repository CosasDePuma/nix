{ domain, safeDir, ... }: { config, lib, ... }: {
  containers = {
    "grafana" = {
      autoStart = true;                                 # Automatically start the container
      ephemeral = true;                                 # Ephemeral container, will not persist data
      privateNetwork = true;                            # Use a private network
      localAddress = "10.100.0.4";                      # Local address for the container
      hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
      bindMounts = {                                    # Bind host folders inside the container
        "/var/lib/grafana" = { isReadOnly = false; hostPath = "${safeDir}/grafana"; };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."vmachines" = config.users.groups."vmachines";
          users."grafana" = {
            uid = lib.mkForce config.users.users."vmachines".uid;
            group = lib.mkForce "vmachines";
            isSystemUser = true;
            shell = "/run/current-system/sw/bin/nologin";
          };
        };
        services.grafana = {
          enable = true;                                # Enable the grafana service
          settings = {
            server = {
              http_addr = "0.0.0.0";                    # Address to listen on
              http_port = 3000;                         # Port to listen on
              domain = "monitor.${domain}";             # Domain for the service
              serve_from_sub_path = true;
            };
          };
        };
        networking = {
          hostName = "grafana";                         # Hostname for the container
          nameservers = [ config.containers."dnsmasq".localAddress ];
          firewall.allowedTCPPorts = [ config.containers."grafana".config.services.grafana.settings.server.http_port ];
        };
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      routers."grafana" = {
        rule = "Host(`monitor.${domain}`)";             # Rule to match the grafana service
        service = "grafana";                            # Service to route to
      };
      services."grafana".loadBalancer.servers = [{      # Backend service
        url = "http://${config.containers."grafana".localAddress}:${toString config.containers."grafana".config.services.grafana.settings.server.http_port}";
      }];
    };
  };
}