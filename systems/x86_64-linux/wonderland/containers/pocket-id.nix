{ domain, safeDir, ... }: { config, ... }: {
  virtualisation.oci-containers.containers."pocket-id" = {
    autoStart = true;                             # Automatically start the container
    image = "ghcr.io/pocket-id/pocket-id:latest"; # Image to use
    hostname = "pocket-id";                       # Container hostname
    environment = {
      APP_URL = "https://auth.${domain}";         # Public URL for the app
      HOST = "0.0.0.0";                           # Address to listen on
      PORT = "8081";                              # Port to listen on
      DB_PROVIDER = "sqlite";                     # Database provider
      TRUST_PROXY = "true";                       # Trust proxy headers
    };
    labels = {                                    # Labels for the container
      "traefik.enable" = "true";                  # Enable Traefik
      "traefik.http.routers.pocket-id.rule" = "Host(`auth.${domain}`)";
      "traefik.http.services.pocket-id.loadbalancer.server.port" = "${toString config.virtualisation.oci-containers.containers."pocket-id".environment.PORT}";
    };
    volumes = [                                   # Volumes to mount
      "${safeDir}/pocket-id:/app/data:rw"
    ];
  };
}