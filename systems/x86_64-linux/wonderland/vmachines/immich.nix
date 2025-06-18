{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
let
  subdomain = "photos.${domain}";
in
{
  containers = {
    "immich" = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      localAddress = "10.100.0.14";
      hostAddress = ipv4;
      bindMounts = {
        "/srv/photos" = {
          isReadOnly = false;
          hostPath = "/mnt/media/photos";
        };
        "${config.containers."komga".config.services.komga.stateDir}" = {
          isReadOnly = false;
          hostPath = "${safeDir}/komga";
        };
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
          enable = true;
          openFirewall = true;
          settings = {
            server.port = 8080;
            servlet.session.timeout = "7d";
            delete-empty-collections = true;
            delete-empty-read-lists = true;
          };
        };
        networking.hostName = "komga";
      };
    };

    # ============================= Proxy =============================

    "caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
      import defaults
      reverse_proxy http://${config.containers."komga".localAddress}:${
        toString config.containers."komga".config.services.komga.settings.server.port
      }
    '';
  };
}
