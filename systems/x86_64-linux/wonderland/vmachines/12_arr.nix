{ domain, safeDir, ... }: { config, lib, pkgs, ... }: {
  containers = {
    "arr" = {
      autoStart = true;                                 # Automatically start the container
      ephemeral = true;                                 # Ephemeral container, will not persist data
      privateNetwork = true;                            # Use a private network
      localAddress = "10.100.0.12";                     # Local address for the container
      hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
      bindMounts = {                                    # Bind host folders inside the container
        "/srv" = { isReadOnly = false; hostPath = "/mnt/media"; };
        "${config.containers."arr".config.services.lidarr.dataDir}" = { isReadOnly = false; hostPath = "${safeDir}/lidarr"; };
        "/var/lib/private/prowlarr" = { isReadOnly = false; hostPath = "${safeDir}/prowlarr"; };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;

        # --- prowlarr (torrents) ---

        services.prowlarr = {
          enable = true;                                # Enable the service
          openFirewall = true;
          settings = {
            server = {
              bindaddress = "0.0.0.0";
              port = 9696;                              # Port for the Prowlarr web interface
            };
          };
        };

        # --- lidarr (music) ---

        services.lidarr = {
          enable = true;                                # Enable the service
          user = "root";                                # User to run the service (needs to write to /srv)
          group = "root";                               # Group to run the service (needs to write to /srv)
          openFirewall = true;
          settings = {
            server = {
              bindaddress = "0.0.0.0";
              port = 8686;
            };
          };
        };
        networking.hostName = "arr";                    # Hostname for the container
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      
      # --- prowlarr ---

      routers."prowlarr" = {
        rule = "Host(`torrent.${domain}`)";              # Rule to match the service
        service = "prowlarr";                            # Service to route to
      };
      services."prowlarr".loadBalancer.servers = [{      # Backend service
        url = "http://${config.containers."arr".localAddress}:${toString config.containers."arr".config.services.prowlarr.settings.server.port}";
      }];

      # --- lidarr ---
      
      routers."lidarr" = {
        rule = "Host(`dl-music.${domain}`)";      # Rule to match the service
        service = "lidarr";                             # Service to route to
      };
      services."lidarr".loadBalancer.servers = [{       # Backend service
        url = "http://${config.containers."arr".localAddress}:${toString config.containers."arr".config.services.lidarr.settings.server.port}";
      }];
    };
  };
}