{ domain, safeDir, ... }: { config, lib, pkgs, ... }: {
  containers = {
    "jellyfin" = {
      autoStart = true;                                 # Automatically start the container
      ephemeral = true;                                 # Ephemeral container, will not persist data
      privateNetwork = true;                            # Use a private network
      localAddress = "10.100.0.10";                     # Local address for the container
      hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
      bindMounts = {                                    # Bind host folders inside the container
       "/srv" = { isReadOnly = true; hostPath = "/mnt/media"; };
      "${config.containers."jellyfin".config.services.jellyfin.configDir}" = { isReadOnly = false; hostPath = "${safeDir}/jellyfin"; };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."vmachines" = config.users.groups."vmachines";
          users."jellyfin" = {
            uid = lib.mkForce config.users.users."vmachines".uid;
            group = lib.mkForce "vmachines";
            isSystemUser = true;
            shell = "/run/current-system/sw/bin/nologin";
          };
        };
        nixpkgs.overlays = [
          (_: prev: { jellyfin-web = prev.jellyfin-web.overrideAttrs (_: _: {
            installPhase = ''
              runHook preInstall
              sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html
              mkdir -p $out/share
              cp -a dist $out/share/jellyfin-web
              runHook postInstall
            '';
          }); })
        ];
        environment.systemPackages = with pkgs; [
          jellyfin jellyfin-web jellyfin-ffmpeg
        ];
        services.jellyfin = {
          enable = true;                                # Enable the jellyfin service
          user = "jellyfin";                            # User to run the service
          group = "vmachines";                          # Group to run the service
          openFirewall = true;
        };
        networking.hostName = "jellyfin";               # Hostname for the container
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      routers."jellyfin" = {
        rule = "Host(`media.${domain}`)";               # Rule to match the komga service
        service = "jellyfin";                           # Service to route to
      };
      services."jellyfin".loadBalancer.servers = [{     # Backend service
        url = "http://${config.containers."jellyfin".localAddress}:8096";
      }];
    };
  };
}