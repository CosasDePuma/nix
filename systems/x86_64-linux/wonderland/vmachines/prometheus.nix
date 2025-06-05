{ domain, safeDir, ... }: { config, lib, ... }: {
  containers = {
    "prometheus" = {
      autoStart = true;                                 # Automatically start the container
      ephemeral = true;                                 # Ephemeral container, will not persist data
      privateNetwork = true;                            # Use a private network
      localAddress = "10.100.0.5";                      # Local address for the container
      hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
      bindMounts = {                                    # Bind host folders inside the container
        "/var/lib/prometheus2/data" = { isReadOnly = false; hostPath = "${safeDir}/prometheus"; };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."vmachines" = config.users.groups."vmachines";
          users."prometheus" = {
            uid = lib.mkForce config.users.users."vmachines".uid;
            group = lib.mkForce "vmachines";
            isSystemUser = true;
            shell = "/run/current-system/sw/bin/nologin";
          };
        };
        services.prometheus = {
          enable = true;                                # Enable the prometheus service
          listenAddress = "0.0.0.0"; port = 8080;       # Address to listen on (prometheus)
          globalConfig = { scrape_interval = "15s"; };  # Global scrape interval
          scrapeConfigs = [
            {
              job_name = "endlessh"; scheme = "http"; static_configs = [{ targets = [
                "${config.containers."endlessh".localAddress}:${toString config.containers."endlessh".config.services.endlessh-go.prometheus.port}"
              ]; }];
            } {
              job_name = "traefik"; scheme = "http"; static_configs = [{ targets = [
                "${config.containers."traefik".localAddress}:${builtins.elemAt (lib.strings.splitString ":" config.containers."traefik".config.services.traefik.staticConfigOptions.entryPoints."metrics".address) 1}"
              ]; }];
            } {
              job_name = "wg-easy"; scheme = "https"; static_configs = [{ targets = [
                "vpn.${domain}:443"
              ]; }];
            }
          ];
        };
        networking = {
          hostName = "prometheus";                      # Hostname for the container
          nameservers = [ config.containers."dnsmasq".localAddress ];
          firewall.allowedTCPPorts = [ config.containers."prometheus".config.services.prometheus.port ];
        };
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      routers."prometheus" = {
        rule = "Host(`metrics.${domain}`)";             # Rule to match the prometheus service
        service = "prometheus";                         # Service to route to
      };
      services."prometheus".loadBalancer.servers = [{   # Backend service
        url = "http://${config.containers."prometheus".localAddress}:${toString config.containers."prometheus".config.services.prometheus.port}";
      }];
    };
  };
}