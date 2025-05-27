{ domain, safeDir, ... }: { config, lib, ... }: {
  containers = {
    "komga" = {
      autoStart = true;                                 # Automatically start the container
      ephemeral = true;                                 # Ephemeral container, will not persist data
      privateNetwork = true;                            # Use a private network
      localAddress = "10.100.0.7";                      # Local address for the container
      hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
      bindMounts = {                                    # Bind host folders inside the container
       "/srv" = { isReadOnly = true; hostPath = "/mnt/media"; };
      "${config.containers."komga".config.services.komga.stateDir}" = { isReadOnly = false; hostPath = "${safeDir}/komga"; };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."vmachines" = config.users.groups."vmachines";
          users."komga" = {
            uid = lib.mkForce config.users.users."vmachines".uid;
            group = lib.mkForce "vmachines";
            isSystemUser = true;
            shell = "/run/current-system/sw/bin/nologin";
          };
        };
        services.komga = {
          enable = true;                                # Enable the komga service
          openFirewall = true;
          settings.server.port = 8080;
        };
        networking.hostName = "komga";                  # Hostname for the container
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      routers."komga" = {
        rule = "Host(`books.${domain}`)";               # Rule to match the komga service
        service = "komga";                              # Service to route to
      };
      services."komga".loadBalancer.servers = [{        # Backend service
        url = "http://${config.containers."komga".localAddress}:${toString config.containers."komga".config.services.komga.settings.server.port}";
      }];
    };
  };
}