{ domain, safeDir, ... }: { config, lib, pkgs, ... }: {
  containers = {
    "torrent" = {
      autoStart = true;                                 # Automatically start the container
      ephemeral = true;                                 # Ephemeral container, will not persist data
      privateNetwork = true;                            # Use a private network
      localAddress = "10.100.0.11";                     # Local address for the container
      hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
      bindMounts = {                                    # Bind host folders inside the container
        "/srv/downloads" = { isReadOnly = false; hostPath = "/mnt/media/downloads"; };
        "/var/lib/deluge" = { isReadOnly = false; hostPath = "${safeDir}/deluge"; };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        services = {

        # --- deluge ---

          deluge = {
            enable = true;                              # Enable the service
            user = "root";                              # User to run the service
            group = "root";                             # Group to run the service
            openFirewall = true;
            web = {
              enable = true;                            # Enable the web interface
              port = 8112;                              # Port for the web interface
              openFirewall = true;                      # Open firewall for the web interface
            };
          };

          # --- flare solverr ---

          flaresolverr = {
            enable = true;
            port = 8191;
            openFirewall = true;
          };
        };
        networking.hostName = "torrent";                # Hostname for the container
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      
      # --- deluge ---
      
      routers."deluge" = {
        rule = "Host(`torrent1.${domain}`)";            # Rule to match the service
        service = "deluge";                             # Service to route to
      };
      services."deluge".loadBalancer.servers = [{       # Backend service
        url = "http://${config.containers."torrent".localAddress}:${toString config.containers."torrent".config.services.deluge.web.port}";
      }];
    };
  };
}