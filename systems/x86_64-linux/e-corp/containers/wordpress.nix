{
  config ? "not imported as a module",
  domain ? "domain not defined",
  safeDir ? "/persist",
  ...
}:
let
  int-ipv4 = "10.200.0.10";
  subdomain = "audea.${domain}";
in
{
  virtualisation.oci-containers.containers = {
    "wordpress-www" = {
      autoStart = true; # Automatically start the container
      image = "wordpress:latest"; # Image to use
      hostname = "wordpress"; # Container hostname
      networks = [ "public" ]; # Networks to connect to
      extraOptions = [ "--ip=${int-ipv4}" ];
      environment = {
        WORDPRESS_DB_HOST = "wordpress-db"; # Enable prometheus metrics
        WORDPRESS_DB_USER = "wordpress"; # Language of the UI
        WORDPRESS_DB_PASSWORD = "wordpress"; # Domain where the service is accessible
        WORDPRESS_DB_NAME = "wordpress"; # Default address for wireguard clients
      };
      dependsOn = [ "wordpress-db" ]; # Dependencies for the container
      volumes = [
        # Volumes to mount
        "${safeDir}/wordpress/www:/var/www/html:rw"
      ];
    };
    "wordpress-db" = {
      autoStart = true; # Automatically start the container
      image = "mariadb:latest"; # Image to use
      hostname = "wordpress-db"; # Container hostname
      networks = [ "public" ]; # Networks to connect to
      environment = {
        MYSQL_ROOT_PASSWORD = "wordpress"; # Root password for the database
        MYSQL_DATABASE = "wordpress"; # Database name
        MYSQL_USER = "wordpress"; # Database user
        MYSQL_PASSWORD = "wordpress"; # Database user password
      };
      volumes = [
        # Volumes to mount
        "${safeDir}/wordpress/db:/var/lib/mysql:rw"
      ];
    };
  };
  containers."caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
    reverse_proxy http://${int-ipv4}:80

    tls /var/lib/acme/${domain}/cert.pem /var/lib/acme/${domain}/key.pem {
      protocols tls1.2 tls1.3
    }
  '';
}
