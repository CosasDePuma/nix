{ domain, safeDir, ... }: { config, ... }: {
  virtualisation.oci-containers.containers = {
    "wordpress-www" = {
      autoStart = true;                             # Automatically start the container
      image = "wordpress:latest";                   # Image to use
      hostname = "wordpress";                       # Container hostname
      networks = [ "public" ];                      # Networks to connect to
      environment = {
        WORDPRESS_DB_HOST = "wordpress-db";         # Enable prometheus metrics
        WORDPRESS_DB_USER = "wordpress";            # Language of the UI
        WORDPRESS_DB_PASSWORD = "wordpress";        # Domain where the service is accessible
        WORDPRESS_DB_NAME = "wordpress";            # Default address for wireguard clients
      };
      labels = {                                    # Labels for the container
        "traefik.enable" = "true";                  # Enable Traefik
        "traefik.http.routers.wordpress.rule" = "Host(`audea.${domain}`)";
        "traefik.http.services.wordpress.loadbalancer.server.port" = "80";
      };
      dependsOn = [ "wordpress-db" ];               # Dependencies for the container
      volumes = [                                   # Volumes to mount
        "${safeDir}/wordpress/www:/var/www/html:rw"
      ];
    };
    "wordpress-db" = {
      autoStart = true;                               # Automatically start the container
      image = "mariadb:latest";                       # Image to use
      hostname = "wordpress-db";                      # Container hostname
      networks = [ "public" ];                        # Networks to connect to
      environment = {
        MYSQL_ROOT_PASSWORD = "wordpress";            # Root password for the database
        MYSQL_DATABASE = "wordpress";                 # Database name
        MYSQL_USER = "wordpress";                     # Database user
        MYSQL_PASSWORD = "wordpress";                 # Database user password
      };
      volumes = [                                     # Volumes to mount
        "${safeDir}/wordpress/db:/var/lib/mysql:rw"
      ];
    };
  };
}