{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  dnsProvider ? throw "no dns provider provided",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
{
  containers."traefik" = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    localAddress = "10.100.0.3";
    hostAddress = ipv4;
    bindMounts = lib.mkMerge [
      {
        "/run/.secrets" = {
          isReadOnly = true;
          hostPath = "/run/agenix";
        };
        "/var/lib/traefik" = {
          isReadOnly = false;
          hostPath = "${safeDir}/traefik";
        };
      }
      (lib.mkIf (config.virtualisation.podman.enable || config.virtualisation.containers.enable) {
        "/var/run/docker.sock" = {
          isReadOnly = true;
          hostPath = "/run/${config.virtualisation.oci-containers.backend}/${config.virtualisation.oci-containers.backend}.sock";
        };
      })
    ];
    config = {

      # ============================= Config =============================

      system.stateVersion = config.system.stateVersion;
      users = {
        groups = {
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
        enable = true;
        environmentFiles = [ "/run/.secrets/acme-token" ];
        staticConfigOptions = {
          accessLog = {
            format = "json";
            filePath = "${config.services.traefik.dataDir}/access.log";
          };
          api = {
            dashboard = true;
            insecure = true;
          };
          certificatesResolvers."letsencrypt".acme = {
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            email = "acme@${domain}";
            keyType = "EC256";
            storage = "${config.services.traefik.dataDir}/acme.json";
            dnsChallenge = {
              provider = dnsProvider;
              delayBeforeCheck = 0;
              resolvers = [
                "1.1.1.1:53"
                "8.8.8.8:53"
              ];
            };
          };
          entryPoints = {
            https = {
              address = ":443";
              asDefault = true;
              http.tls = {
                certResolver = "letsencrypt";
                domains = [
                  {
                    main = domain;
                    sans = [ "*.${domain}" ];
                  }
                ];
              };
            };
            metrics.address = ":8081";
          };
          global = {
            checkNewVersion = false;
            sendAnonymousUsage = false;
          };
          log = {
            compress = true;
            format = "json";
            level = "DEBUG";
          };
          metrics.prometheus = {
            entryPoint = "metrics";
            addRoutersLabels = true;
          };
          ping.entryPoint = "https";
          providers.docker =
            lib.mkIf (config.virtualisation.podman.enable || config.virtualisation.containers.enable)
              {
                endpoint = "unix:///var/run/docker.sock";
                network = "public";
                exposedByDefault = false;
                watch = true;
              };
        };
        dynamicConfigOptions = {
          http.middlewares = {
            default.chain.middlewares = [
              "compression@file"
              "jokes@file"
              "security@file"
            ];
            security.chain.middlewares = [
              "security-headers@file"
              "ssl-headers@file"
              "rate-limiting@file"
            ];

            compression.compress = {
              minResponseBodyBytes = 1024;
              excludedContentTypes = [ "text/event-stream" ];
            };

            error-pages.errors = {
              status = "403-404";
              service = "vhost";
              query = "{url}";
            };

            jokes.headers.customRequestHeaders = {
              Server = "'; DROP TABLE users; -- --";
              X-Clacks-Overhead = "GNU Pumita";
              X-Joke = "What is the best thing about Switzerland? I don't know, but the flag is a big plus.";
              X-NaNaNaNaNaNaNaNa = "Batman!";
              X-PoweredBy = "Pumas, unicorns and rainbows </3";
            };

            security-headers.headers = {
              browserXssFilter = true;
              contentTypeNosniff = true;
              frameDeny = true;
              isDevelopment = false;
              permissionsPolicy = "accelerometer=(), bluetooth=(), camera=(), geolocation=(), microphone=(), payment=(), usb=()";
              customRequestHeaders = {
                Cross-Origin-Embedder-Policy = "require-corp";
                Cross-Origin-Opener-Policy = "same-origin";
                Cross-Origin-Resource-Policy = "same-site";
                X-DNS-Prefetch-Control = "off";
              };
            };

            ssl-headers.headers = {
              sslRedirect = true;
              stsIncludeSubdomains = true;
              stsPreload = true;
              stsSeconds = 31536000;
              customRequestHeaders = {
                X-Forwarded-Proto = "https";
              };
            };

            rate-limiting.rateLimit = {
              average = 50;
              period = "1s";
            };
          };

          tls.options."default" = {
            minVersion = "VersionTLS12";
            sniStrict = true;
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
              "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
              "TLS_FALLBACK_SCSV"
            ];
            curvePreferences = [
              "secp521r1"
              "secp384r1"
            ];
          };
        };
      };
      networking = {
        hostName = "traefik";
        firewall.allowedTCPPorts =
          [ 8080 ]
          ++ builtins.map (e: lib.strings.toInt (builtins.elemAt (lib.strings.splitString ":" e.address) 1)) (
            builtins.attrValues
              config.containers."traefik".config.services.traefik.staticConfigOptions.entryPoints
          );
      };
    };
  };
}
