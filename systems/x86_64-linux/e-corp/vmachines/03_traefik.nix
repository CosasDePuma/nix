{ dnsProvider, domain, safeDir, ... }: { config, lib, ... }: {
  containers."traefik" = {
    autoStart = true;                                 # Automatically start the container
    ephemeral = true;                                 # Ephemeral container, will not persist data
    privateNetwork = true;                            # Use a private network
    localAddress = "10.100.0.3";                      # Local address for the container
    hostAddress = (builtins.head config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses).address;
    bindMounts = lib.mkMerge [{                       # Bind host folders inside the container
        "/run/.secrets"        = { isReadOnly = true;  hostPath = "/run/agenix"; };
        "/var/lib/traefik"     = { isReadOnly = false; hostPath = "${safeDir}/traefik"; };
      }
      (lib.mkIf (config.virtualisation.podman.enable || config.virtualisation.containers.enable) {
      "/var/run/docker.sock" = { isReadOnly = true;  hostPath = "/run/${config.virtualisation.oci-containers.backend}/${config.virtualisation.oci-containers.backend}.sock"; };
      })
    ];
    config = {

      # ============================= Config =============================

      system.stateVersion = config.system.stateVersion;
      users = {
        groups = {                                    # Mimic groups from the host system
          "podman" = config.users.groups."podman";
          "vmachines" = config.users.groups."vmachines";
        };
        users."traefik" = {
          inherit (config.users.users."vmachines") uid;
          group = lib.mkForce "vmachines";
          isSystemUser = true;
          shell = "/run/current-system/sw/bin/nologin";
          extraGroups = [ "podman" ];
        };
      };
      services.traefik = {
        enable = true;                                # Enable the Traefik service
        environmentFiles = [ "/run/.secrets/acme-token" ];
        staticConfigOptions = {
          accessLog = {
            format = "json";                          # Log format
            filePath = "${config.services.traefik.dataDir}/access.log";
          };
          api = {
            dashboard = true;                         # Enable the Traefik dashboard
            insecure = true;                          # FIXME(security): Remove this and implement a proper auth setup
          };
          certificatesResolvers."letsencrypt".acme = {
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            email = "acme@${domain}";                 # Email for ACME notifications
            keyType = "EC256";                        # Key type for SSL certificates
            storage = "${config.services.traefik.dataDir}/acme.json";
            dnsChallenge = {                          # DNS-01 challenge
              provider = dnsProvider;                 # DNS provider
              delayBeforeCheck = 0;                   # Delay before checking
              resolvers = [ "1.1.1.1:53" "8.8.8.8:53" ];
            };
          };
          entryPoints = {
            https = {
              address = ":443";                       # Port to listen on (HTTPS)
              asDefault = true;                       # Set as default entrypoint
              http.tls = {                            # Use TLS
                certResolver = "letsencrypt";         # Certificate resolver
                domains = [ { main = domain; sans = [ "*.${domain}" ]; } ];
              };
            };
            metrics.address = ":8081";                # Port to listen on (metrics)
          };
          global = {
            checkNewVersion = false;                  # Disable version checks
            sendAnonymousUsage = false;               # Disable anonymous usage reporting
          };
          log = {
            compress = true;                          # Compress logs
            format = "json";                          # Log format
            level = "DEBUG";                          # Log level
          };
          metrics.prometheus = {                      # Enable Prometheus metrics
            entryPoint = "metrics";                   # Entrypoint for prometheus
            addRoutersLabels = true;                  # Add routers labels
          };
          ping.entryPoint = "https";                  # Entrypoint for ping
          providers.docker = lib.mkIf (config.virtualisation.podman.enable || config.virtualisation.containers.enable) {
            endpoint = "unix:///var/run/docker.sock"; # Docker socket
            network = "public";                       # Network to use
            exposedByDefault = false;                 # Disable automatic exposure of containers
            watch = true;                             # Watch for changes in Docker containers
          };
        };
        dynamicConfigOptions = {
          http.middlewares = {
            # --- chains ---
            default.chain.middlewares  = [ "compression@file" "jokes@file" "security@file" ]; # TODO(improvement): Default error pages "error-pages@file" 
            security.chain.middlewares = [ "security-headers@file" "ssl-headers@file" "rate-limiting@file" ];

            # --- compression ---
            compression.compress = {
              minResponseBodyBytes = 1024;            # Minimum response body size to compress
              excludedContentTypes = [ "text/event-stream" ];
            };

            # --- error pages ---
            error-pages.errors = {  # TODO(improvement): Default error pages "error-pages@file" 
              status = "403-404";
              service = "vhost";
              query = "{url}";
            };

            # --- jokes ---
            jokes.headers.customRequestHeaders = {
              Server = "'; DROP TABLE users; -- --";
              X-Clacks-Overhead = "GNU Pumita";
              X-Joke = "What is the best thing about Switzerland? I don't know, but the flag is a big plus.";
              X-NaNaNaNaNaNaNaNa = "Batman!";
              X-PoweredBy = "Pumas, unicorns and rainbows </3";
            };

            # --- security-headers ---
            security-headers.headers = {
              browserXssFilter = true;                # Enable XSS filter
              contentTypeNosniff = true;              # Enable content type nosniff
              frameDeny = true;                       # Enable frame deny
              isDevelopment = false;                  # Enable development mode
              permissionsPolicy = "accelerometer=(), bluetooth=(), camera=(), geolocation=(), microphone=(), payment=(), usb=()";
              customRequestHeaders = {
                Cross-Origin-Embedder-Policy = "require-corp";
                Cross-Origin-Opener-Policy = "same-origin";
                Cross-Origin-Resource-Policy = "same-site";
                X-DNS-Prefetch-Control = "off";
              };
            };

            # --- ssl-headers ---
            ssl-headers.headers = {
              sslRedirect = true;                     # Redirect to HTTPS
              stsIncludeSubdomains = true;            # Include subdomains in HSTS
              stsPreload = true;                      # Enable HSTS preload
              stsSeconds = 31536000;                  # HSTS seconds
              customRequestHeaders = {
                X-Forwarded-Proto = "https";          # Forwarded protocol
              };
            };

            # --- rate-limiting ---
            rate-limiting.rateLimit = {
              average = 50;                          # Average requests per second
              period  = "1s";                        # Period
            };
          };

          # ---------------------------------- TLS -----------------------------------

          tls.options."default" = {                  # Default TLS options
            minVersion = "VersionTLS12";             # Minimum TLS version
            sniStrict = true;                        # Strict SNI
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384" 
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
              "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
              "TLS_FALLBACK_SCSV"
            ];
            curvePreferences = [ "secp521r1" "secp384r1" ];
          };
        };
      };
      networking = {
        hostName = "traefik";                        # Hostname for the container
        firewall.allowedTCPPorts = [8080] ++         # Open the firewall
          builtins.map (e: lib.strings.toInt (builtins.elemAt (lib.strings.splitString ":" e.address) 1))
            (builtins.attrValues config.containers."traefik".config.services.traefik.staticConfigOptions.entryPoints);
      };
    };
  };
}