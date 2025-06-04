{ domain, safeDir, ... }: { config, lib, pkgs, ... }: {
  containers = {
    "wordpress" = {
      autoStart = true;                                 # Automatically start the container
      ephemeral = true;                                 # Ephemeral container, will not persist data
      privateNetwork = true;                            # Use a private network
      localAddress = "10.100.0.4";                      # Local address for the container
      hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
      bindMounts = {                                    # Bind host folders inside the container
        "/var/lib/wordpress" = { isReadOnly = false; hostPath = "${safeDir}/wordpress"; };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."vmachines" = config.users.groups."vmachines";
          users."wordpress" = {
            inherit (config.users.users."vmachines") uid;
            group = lib.mkForce "vmachines";
            isSystemUser = true;
            shell = "/run/current-system/sw/bin/nologin";
          };
        };
        services.wordpress = {
          sites = {
            "audea.${domain}" = {
              themes = {
                inherit (pkgs.wordpressPackages.themes)
                  twentytwentythree;
              };
              plugins = {
                inherit (pkgs.wordpressPackages.plugins)
                  disable-xml-rpc
                  jetpack
                  merge-minify-refresh
                  simple-login-captcha
                  webp-express
                  wordpress-seo
                  wp-gdpr-compliance
                  wp-statistics;
              };
              extraConfig = ''
                // Error logging
                ini_set( 'error_log', '/var/lib/wordpress/audea.${domain}/debug.log' );
                // Force SSL for the site
                $_SERVER['HTTPS']='on';
                // Enable the plugins
                if ( !defined('ABSPATH') )
                  define('ABSPATH', dirname(__FILE__) . '/');
                require_once(ABSPATH . 'wp-settings.php');
                require_once ABSPATH . 'wp-admin/includes/plugin.php';
                activate_plugin( 'disable-xml-rpc/disable-xml-rpc.php' );
                activate_plugin( 'simple-login-captcha/simple-login-captcha.php' );
              '';
              settings = {
                AUTOMATIC_UPDATER_DISABLED = true;
                FORCE_SSL_ADMIN = true;
                WP_DEFAULT_THEME = "twentytwentythree";
              };
            };
          };
        };
        nixpkgs.overlays = [
          (_: super: {
            wordpress = super.wordpress.overrideAttrs (oldAttrs: rec {
              installPhase = oldAttrs.installPhase + ''
                ln -s /var/lib/wordpress/audea.${domain}/mmr $out/share/wordpress/wp-content/mmr
                ln -s /var/lib/wordpress/audea.${domain}/webp-express $out/share/wordpress/wp-content/webp-express
              '';
            });
          })
        ];
        systemd.tmpfiles.rules = [
          "d '/var/lib/wordpress/audea.${domain}/mmr' 0750 wordpress vmachines - -"
          "d '/var/lib/wordpress/audea.${domain}/webp-express' 0750 wordpress vmachines - -"
        ];
        networking = {
          hostName = "wordpress";                      # Hostname for the container
          firewall.allowedTCPPorts = [ 80 ];
        };
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      routers."wordpress" = {
        rule = "Host(`audea.${domain}`)";             # Rule to match the wordpress service
        service = "wordpress";                        # Service to route to
      };
      services."wordpress".loadBalancer.servers = [{   # Backend service
        url = "http://${config.containers."wordpress".localAddress}:80";
      }];
    };
  };
}