{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
{
  containers."caddy" = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    localAddress = "10.100.0.3";
    hostAddress = ipv4;
    bindMounts = {
      "/run/agenix" = {
        isReadOnly = true;
        hostPath = "/run/agenix";
      };
      "/var/lib/acme" = {
        isReadOnly = true;
        hostPath = "/var/lib/acme";
      };
      "${config.containers."caddy".config.services.caddy.dataDir}" = {
        isReadOnly = false;
        hostPath = "${safeDir}/caddy";
      };
    };
    config = {

      # ============================= Config =============================

      system.stateVersion = config.system.stateVersion;
      users = {
        users."caddy" = {
          uid = lib.mkForce config.users.users."vmachines".uid;
          group = "caddy";
        };
        groups."caddy".gid = lib.mkForce config.users.groups."vmachines".gid;
      };

      # --- caddy

      services.caddy = {
        enable = true;
        group = "caddy";
        enableReload = true;
        logFormat = "level INFO";
        globalConfig = ''
          #metrics {
          #  per_host
          #}
        '';
        extraConfig = ''
          (default-headers) {
            import joke-headers
            import security-headers
            import unwanted-headers
          }
          (joke-headers) {
            header {
              >server "'; DROP TABLE users; -- --"
              >x-clacks-overhead "GNU Pumita"
              >x-joke "What is the best thing about Switzerland? I don't know, but the flag is a big plus."
              >x-nananananananana "Batman!"
              >x-poweredby "Pumas, unicorns and rainbows </3"
            }
          }
          (security-headers) {
            header {
              >cross-origin-embedder-policy "require-corp"
              >cross-origin-opener-policy "same-origin"
              >cross-origin-resource-policy "same-origin"
              >frame-deny "sameorigin"
              >permissions-policy "camera=(), geolocation=(), interest-cohort=(), microphone=()"
              >referrer-policy "strict-origin"
              >strict-transport-security "max-age=31536000; includeSubDomains; preload"
              >x-content-type-options "nosniff"
              >x-frame-options "deny"
            }
          }
          (tls) {
            tls /var/lib/acme/${domain}/cert.pem /var/lib/acme/${domain}/key.pem {
              protocols tls1.2 tls1.3
              curves x25519mlkem768 secp256r1 secp384r1
              ciphers TLS_AES_256_GCM_SHA384 TLS_AES_128_GCM_SHA256 TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 
            }
          }
          (unwanted-headers) {
            header {
              -expect-ct
              -via
              -x-aspnet-version
              -x-aspnetmvc-version
              -x-xss-protection
            }
          }
        '';
      };
      networking = {
        hostName = "caddy";
        firewall.allowedTCPPorts = [ 443 ];
      };
    };
  };
}
