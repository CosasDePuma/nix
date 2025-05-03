{ config, lib, pkgs, namespace, ... }:
let
  user      = "joker";       nas = "192.168.1.3";
  ipv4      = "192.168.1.2"; gw4 = "192.168.1.1";
  domain    = "kike.wtf"; provider = "cloudflare";
  sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos";
in rec {
  # +----------------------------------------------------------------------------+
  # |                                  Hardware                                  |
  # +----------------------------------------------------------------------------+

  "${namespace}".disko.disk = "/dev/sda";             # Hardware disk used by disko to create the partitions (module!)

  # +----------------------------------------------------------------------------+
  # |                            Internationalization                            |
  # +----------------------------------------------------------------------------+

  # ================================ Timezone ===================================

  time.timeZone = "Europe/Madrid";                    # System timezone

  # +----------------------------------------------------------------------------+
  # |                                  Network                                   |
  # +----------------------------------------------------------------------------+

  # ==================================== DNS =====================================

  networking.hostName = "arkham";                     # Hostname (also used by Flake)
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];   # Default DNS resolvers

  # ================================= Firewall ===================================

  networking.firewall = {
    enable = true;                                    # Enable firewall
    allowedUDPPorts = [ ];                            # Disallow all UDP ports
    allowedTCPPorts = lib.lists.unique                # Allowed TCP ports
      # --- traefik ---
      (builtins.map (p: p.hostPort) config.containers."traefik".forwardPorts) ++
      # --- endlessh ---
      (builtins.map (p: p.hostPort) config.containers."endlessh".forwardPorts);
  };

  # ================================= Interfaces =================================

  networking.usePredictableInterfaceNames = false;    # Disable modern interface names
  networking.interfaces."eth0".ipv4.addresses = [     # Default interface name
    { address = ipv4; prefixLength = 24; }            # Static IPv4 address
  ];
  networking.defaultGateway = {                       # Default gateway
    interface = "eth0"; address = gw4;
  };

  # +----------------------------------------------------------------------------+
  # |                              Package Manager                               |
  # +----------------------------------------------------------------------------+

  # ============================= Garbage Collection =============================

  nix.gc = {
    automatic = true;                                 # Enable automatic garbage collection
    dates = "weekly";                                 # Weekly removes old packages and generations
    options = "--delete-older-than 7d";               # Removes everything older than 7 days
    persistent = true;                                # Ensures that garbage collection is executed
  };

  # +----------------------------------------------------------------------------+
  # |                                  Services                                  |
  # +----------------------------------------------------------------------------+

  # ============================= DDNS (Dynamic DNS) =============================

  services.duckdns = {
    enable = true;                                    # Enable the DuckDNS service
    tokenFile = "/run/agenix/duckdns-token";          # DuckDNS token (secret)
    domains = [ (builtins.replaceStrings ["."] [""] domain) ];
  };

  # ====================== IDS (Intrusion Detection System) ======================

  services.fail2ban = {
    enable = true;                                    # Enable the Fail2Ban service
    maxretry = 3;                                     # Maximum number of failed attempts
    bantime = "1h";                                   # Ban time (1 hour)
    bantime-increment.enable = true;                  # Enable incremental ban time
    bantime-increment.factor = "24";                  # Increment factor (1h, 1d, 24d, 1,5y, 37y, ...)
    banaction = "%(banaction_allports)s";             # Ban access to all ports
  };

  # ============================= SSH (Secure Shell) =============================

  services.openssh = {
    enable = true;                                    # Enable the OpenSSH service
    ports = [ 64022 ];                                # Obfuscated port to evade automated scanning bots
    openFirewall = true;                              # Always allow SSH connections
    startWhenNeeded = true;                           # Resource-efficient socket activation
    banner = ''
      ==============================================================
      |                   AUTHORIZED ACCESS ONLY                   |
      ==============================================================
      |                                                            |
      |    WARNING: All connections are monitored and recorded.    |
      |  Disconnect IMMEDIATELY if you are not an authorized user! |
      |                                                            |
      |       *** Unauthorized access will be prosecuted ***       |
      |                                                            |
      ==============================================================
    '';
    settings = {
      AllowUsers = [ "${user}" ];                     # Allow only the specified user to connect
      ChallengeResponseAuthentication = false;        # Disable password-based authentication (I)
      IgnoreRhosts = true;                            # Disable Rhosts-based authentication
      KbdInteractiveAuthentication = false;           # Disable password-based authentication (II)
      LoginGraceTime = 30;                            # Grace period for user authentication (30 seconds)
      MaxAuthTries = 3;                               # Maximum authentication attempts before locking
      MaxSessions = 5;                                # Maximum concurrent SSH sessions preventing exhaustion
      MaxStartups = "10:30:60";                       # Graceful anti-flood
      PermitEmptyPasswords = false;                   # Disable empty password authentication
      PasswordAuthentication = false;                 # Disable password-based authentication (III)
      PermitRootLogin = "no";                         # Prevent root login via SSH
      X11Forwarding = false;                          # Disable graphical forwarding
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com" "aes128-gcm@openssh.com" "aes256-ctr" "aes192-ctr" "aes128-ctr"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com" "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
      KexAlgorithms = [
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512" "diffie-hellman-group18-sha512"
      ];
    };
  };
  security.pam.sshAgentAuth.enable = true;            # Enable SSH agent authentication
  security.pam.services."sudo".sshAgentAuth = true;   # Enable sudo via SSH agent

  # +----------------------------------------------------------------------------+
  # |                                  Secrets                                  |
  # +----------------------------------------------------------------------------+

  age.secrets = let mkSecret = file: { inherit file; owner = "root"; group = "root"; mode = "0400"; }; in {
    "acme-token"         = mkSecret ./secrets/acme-token.age;
    "duckdns-token"      = mkSecret ./secrets/duckdns-token.age;
    "smb-credentials"    = mkSecret ./secrets/smb-credentials.age;
    "vaultwarden-passwd" = mkSecret ./secrets/vaultwarden-passwd.age;
  };

  # +----------------------------------------------------------------------------+
  # |                                  Security                                  |
  # +----------------------------------------------------------------------------+
  
  # ============================ Privilege Escalation ============================

  security.sudo-rs = {                                # Memory-safe sudo replacement
    enable = true;                                    # Enable super user privileges
    execWheelOnly = true;                             # Only allow 'wheel' group to execute 'sudo'
    wheelNeedsPassword = true;                        # Force password authentication
  };

  # +----------------------------------------------------------------------------+
  # |                                   System                                   |
  # +----------------------------------------------------------------------------+

  # ================================ Auto-Upgrade ================================

  system.autoUpgrade = {
    enable = true;                                    # Enable auto-upgrades
    flake = "github:cosasdepuma/nix";                 # Flake to use for auto-upgrades
    dates = "daily";                                  # Daily checks for updates
    operation = "switch";                             # Switches to the new system immediately
    persistent = true;                                # Ensures that auto-upgrades are executed
  };

  # ================================= Filesystem =================================

  fileSystems."/mnt/media" = {
    device = "//${nas}/Media";
    fsType = "cifs";
    options = [ "credentials=/run/agenix/smb-credentials" "nofail" "x-systemd.automount" "x-systemd.mount-timeout=30s" ];
  };
  environment.systemPackages = with pkgs; [ cifs-utils ];

  systemd.tmpfiles.rules = lib.flatten (lib.mapAttrsToList (_: container:
    lib.mapAttrsToList (_: mount:
      lib.optional (lib.hasPrefix "/persistent" mount.hostPath) 
        "d ${mount.hostPath} 0700 root root -"
    ) (container.bindMounts or {})
  ) config.containers);

  # ================================== Release ===================================

  system.stateVersion = "25.05";

  # +----------------------------------------------------------------------------+
  # |                                   Users                                    |
  # +----------------------------------------------------------------------------+

  # =================================== Groups ===================================

  users.groups."users" = {};                          # Group to organize regular users

  # =================================== Users ====================================

  users.users."${user}" = {
    createHome = true;
    description = "Why so serious? ;)";               # Gotham reference
    home = "/home/users/${user}";                     # Create home directory inside 'users' folder
    password = null;                                  # Disable password authentication
    isNormalUser = true;                              # Regular user account
    useDefaultShell = true;                           # Use default shell
    extraGroups = [ "wheel" ];                        # Grant superuser privileges
    openssh.authorizedKeys.keys = [ sshPubKey ];      # Authorized SSH keys
  };

  # +----------------------------------------------------------------------------+
  # |                              Virtual Machines                              |
  # +----------------------------------------------------------------------------+

  # ================================= Networking =================================

  networking.nat = {
    enable = true;                                    # Enable NAT
    internalInterfaces = [ "ve-+" ];                  # Internal interfaces used by containers
    externalInterface = builtins.head (builtins.attrNames config.networking.interfaces);
    enableIPv6 = false;                               # Disable IPv6 NAT
  };

  # ================================= Machines ==================================
  
  containers = let
    mkVM = addr4: cfg: {
      autoStart = true;                               # Automatically start the container
      ephemeral = true;                               # Automatically delete the container on shutdown
      privateNetwork = true;                          # Enable private networks for containers
      hostAddress = ipv4; localAddress = addr4;       # Set the host and local addresses
      config = { system.stateVersion = config.system.stateVersion; } // cfg;
    };
  in {

    # ------------------------ Tarpit: HTTP (Web Server) -------------------------

    "vhost" = mkVM "10.0.0.2" {
      services.nginx = {
        enable = true;
        defaultListen = [{ addr = "0.0.0.0"; port = 80; }];
        virtualHosts = {
          "default" = {
            default = true;
            extraConfig = "error_page 301 @30x; charset utf-8; source_charset utf-8;";
            locations = {
              "/" = { root = ./metafiles; tryFiles = "$uri @redirect"; };
              "@30x" = { return = "200 ''"; extraConfig = "default_type '';"; };
              "@redirect".return = "301 https://www.youtube.com/watch?v=dQw4w9WgXc"; };
          };
        };
      };
      networking.firewall.allowedTCPPorts = builtins.map (listen: listen.port) config.containers."vhost".config.services.nginx.defaultListen;
    };

    # ------------------------ Tarpit: SSH (Secure Shell) ------------------------

    "endlessh" = mkVM "10.0.0.1" {
      services.endlessh-go = {
        enable = true;                                # Enable the endlessh service
        listenAddress = "0.0.0.0"; port = 22;         # Address to listen on (ssh)
        openFirewall = true;                          # Open the firewall for the service
        prometheus = {
          enable = true;                              # Enable Prometheus metrics
          listenAddress = "0.0.0.0"; port = 2121;     # Address to listen on (prometheus)
        };
      };
      networking.firewall.allowedTCPPorts = [ config.containers."endlessh".config.services.endlessh-go.prometheus.port ];
    } // { forwardPorts = [ { hostPort = 22; containerPort = config.containers."endlessh".config.services.endlessh-go.port; } ]; };

    # ---------------------------- Metrics Dashboard -----------------------------

    "grafana" = mkVM "10.0.0.12" {
      services.grafana = {
        enable = true;                                # Enable the grafana service
        settings = {                                  # Grafana settings
          server = {
            domain = "metrics.${domain}";             # Domain where the service is accessible
            http_addr = "0.0.0.0"; http_port = 80;    # Address to listen on (grafana)
            serve_from_sub_path = true;               # Serve from sub-path
          };
        };
      };
      networking.firewall.allowedTCPPorts = [ config.containers."grafana".config.services.grafana.settings.server.http_port ];
    } // { bindMounts."/var/lib/grafana/data" = { hostPath = "/persistent/grafana"; isReadOnly = false; }; };

    # ---------------------------- Metrics Monitoring ----------------------------

    "prometheus" = mkVM "10.0.0.11" {
      services.prometheus = {
        enable = true;                                # Enable the prometheus service
        listenAddress = "0.0.0.0"; port = 8080;       # Address to listen on (prometheus)
        globalConfig = {
          scrape_interval = "15s";
        };
        scrapeConfigs = [
          {
            job_name = "endlessh"; static_configs = [{ targets = [
              "${config.containers."endlessh".localAddress}:${toString config.containers."endlessh".config.services.endlessh-go.prometheus.port}"
            ]; }];
          } {
            job_name = "traefik"; static_configs = [{ targets = [
              "${config.containers."traefik".localAddress}:${builtins.elemAt (lib.strings.splitString ":" config.containers."traefik".config.services.traefik.staticConfigOptions.entryPoints."metrics".address) 1}"
            ]; }];
          }
        ];
      };
      networking.firewall.allowedTCPPorts = [ config.containers."prometheus".config.services.prometheus.port ];
    } // { bindMounts."/var/lib/prometheus2/data" = { hostPath = "/persistent/prometheus"; isReadOnly = false; }; };

    # ----------------------------- Password Manager -----------------------------

    "vaultwarden" = mkVM "10.0.0.13" {
      services.vaultwarden = {
        enable = true;                                # Enable the prometheus service
        dbBackend = "sqlite";                         # Database backend
        config = {
          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = 8000;                         # Port to listen on
          DOMAIN = "https://vault.${domain}";         # Domain where the service is accessible
          INVITATIONS_ALLOWED = true;                 # Enable invitations (only admins can invite users)
          SHOW_PASSWORD_HINT = false;                 # Disable password hints
          SIGNUPS_ALLOWED = false;                    # Disable signups
        };
        environmentFile = "/run/.secrets/vaultwarden-passwd";
      };
      networking.firewall.allowedTCPPorts = [ config.containers."vaultwarden".config.services.vaultwarden.config.ROCKET_PORT ];
    } // { bindMounts = {
      "/run/.secrets" = { hostPath = "/run/agenix"; isReadOnly = true; };
      "/var/lib/vaultwarden" = { hostPath = "/persistent/vaultwarden"; isReadOnly = false; };
    }; };

    # --------------------- Open Publication Distribution ---------------------

    "komga" = mkVM "10.0.0.14" {
      services.komga = {
        enable = true;
        openFirewall = true;
        settings.server.port = 8080;
      };
    } // { bindMounts = {
      "/mnt/media" = { hostPath = "/mnt/media"; isReadOnly = true; };
      "/var/lib/komga" = { hostPath = "/persistent/komga"; isReadOnly = false; };
    }; };

    # ----------------------------- Reverse Proxy -----------------------------

    "traefik" = mkVM "10.0.0.10" {
      services.traefik = {
        enable = true;                                    # Enable the Traefik service
        environmentFiles = [ "/run/.secrets/acme-token" ];
        staticConfigOptions = {
          accessLog = {
            format = "json";                              # Log format
            filePath = "${config.services.traefik.dataDir}/access.log";
          };
          api = {
            dashboard = true;                             # Enable the Traefik dashboard
            insecure = true;                              # FIXME: Remove this and implement a proper auth setup
          };
          certificatesResolvers."letsencrypt".acme = {
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            email = "acme@${domain}";                     # Email for ACME notifications
            keyType = "EC256";                            # Key type for SSL certificates
            storage = "${config.services.traefik.dataDir}/acme.json";
            dnsChallenge = {                              # DNS-01 challenge
              inherit provider;                           # DNS provider
              delayBeforeCheck = 0;                       # Delay before checking
              resolvers = [ "1.1.1.1:53" "8.8.8.8:53" ];  # DNS resolvers for DNS-01 challenges
            };
          };
          entryPoints = {
            https = {
              address = ":443";                           # Port to listen on (HTTPS)
              asDefault = true;                           # Set as default entrypoint
              http.tls = {                                # Use TLS
                certResolver = "letsencrypt";             # Certificate resolver
                domains = [ { main = domain; sans = [ "*.${domain}" ]; } ];
              };
            };
            metrics.address = ":8081";                    # Port to listen on (metrics)
          };
          global = {
            checkNewVersion = false;                      # Disable version checks
            sendAnonymousUsage = false;                   # Disable anonymous usage reporting
          };
          log = {
            compress = true;                              # Compress logs
            format = "json";                              # Log format
            level = "DEBUG";                              # Log level
          };
          metrics.prometheus = {                          # Enable Prometheus metrics
            entryPoint = "metrics";                       # Entrypoint for prometheus
            addRoutersLabels = true;                      # Add routers labels
          };
          ping.entryPoint = "https";                      # Entrypoint for ping
        };
        dynamicConfigOptions = {
          http = {
            # ------------------------------- Routes ---------------------------------

            # --- root (sub)domain ---
            routers."vhost"  = { rule = "HostRegexp(`.*`)"; service = "vhost"; };
            services."vhost".loadBalancer.servers = [{
              url = "http://${config.containers."vhost".localAddress}:${toString (builtins.head config.containers."vhost".config.services.nginx.defaultListen).port}"; }];

            # --- books subdomain ---
            routers."komga"  = { rule = "Host(`books.${domain}`)"; service = "komga"; };
            services."komga".loadBalancer.servers = [{
              url = "http://${config.containers."komga".localAddress}:${toString config.containers."komga".config.services.komga.settings.server.port}"; }];

            # --- metrics subdomain ---
            routers."grafana"  = { rule = "Host(`metrics.${domain}`)"; service = "grafana"; };
            services."grafana".loadBalancer.servers = [{
              url = "http://${config.containers."grafana".localAddress}:${toString config.containers."grafana".config.services.grafana.settings.server.http_port}"; }];

            # --- monitor subdomain ---
            routers."prometheus"  = { rule = "Host(`monitor.${domain}`)"; service = "prometheus"; };
            services."prometheus".loadBalancer.servers = [{
              url = "http://${config.containers."prometheus".localAddress}:${toString config.containers."prometheus".config.services.prometheus.port}"; }];

            # --- vault subdomain ---
            routers."vaultwarden"  = { rule = "Host(`vault.${domain}`)"; service = "vaultwarden"; };
            services."vaultwarden".loadBalancer.servers = [{
              url = "http://${config.containers."vaultwarden".localAddress}:${toString config.containers."vaultwarden".config.services.vaultwarden.config.ROCKET_PORT}"; }];

            # ----------------------------- Middlewares ------------------------------

            middlewares = {
              # --- chains ---
              default.chain.middlewares  = [ "compression@file" "error-pages@file" "jokes@file" ]; #FIXME: "security@file" ];
              security.chain.middlewares = [ "security-headers@file" "ssl-headers@file" "rate-limiting@file" ];

              # --- compression ---
              compression.compress = {
                minResponseBodyBytes = 1024;                # Minimum response body size to compress
                excludedContentTypes = [ "text/event-stream" ];
              };

              # --- error pages ---
              error-pages.errors = {
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
                browserXssFilter = true;                    # Enable XSS filter
                contentTypeNosniff = true;                  # Enable content type nosniff
                frameDeny = true;                           # Enable frame deny
                isDevelopment = false;                      # Enable development mode
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
                sslRedirect = true;                         # Redirect to HTTPS
                stsIncludeSubdomains = true;                # Include subdomains in HSTS
                stsPreload = true;                          # Enable HSTS preload
                stsSeconds = 31536000;                      # HSTS seconds
                customRequestHeaders = {
                  X-Forwarded-Proto = "https";              # Forwarded protocol
                };
              };

              # --- rate-limiting ---
              rate-limiting.rateLimit = {
                average = 50;                               # Average requests per second
                period  = "1s";                             # Period
              };
            };
          };

          # ---------------------------------- TLS -----------------------------------

          tls.options."default" = {                       # Default TLS options
            minVersion = "VersionTLS12";                  # Minimum TLS version
            sniStrict = true;                             # Strict SNI
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
      networking.firewall.allowedTCPPorts = [8080] ++
        builtins.map (e: lib.strings.toInt (builtins.elemAt (lib.strings.splitString ":" e.address) 1))
          (builtins.attrValues config.containers."traefik".config.services.traefik.staticConfigOptions.entryPoints);
    } // {
      forwardPorts = [{ hostPort = 443; containerPort = lib.strings.toInt (builtins.elemAt (lib.strings.splitString ":" config.containers."traefik".config.services.traefik.staticConfigOptions.entryPoints."https".address) 1); }];
      bindMounts = {
        "/run/.secrets" = { hostPath = "/run/agenix"; isReadOnly = true; };
        "/var/lib/traefik" = { hostPath = "/persistent/traefik"; isReadOnly = false; };
      };
    };
  };
}