{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
{
  containers = {
    "torrents" = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      localAddress = "10.100.0.254";
      hostAddress = ipv4;
      bindMounts = {
        "/srv/downloads" = {
          isReadOnly = false;
          hostPath = "/mnt/media/.downloads";
        };
        "/var/lib/deluge" = {
          isReadOnly = false;
          hostPath = "${safeDir}/deluge";
        };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.strings.getName pkg) [
            "unrar"
          ];

        services = {

          # --- deluge

          deluge = {
            enable = true;
            user = "root";
            group = "root";
            openFirewall = true;
            web = {
              enable = true;
              port = 8112;
              openFirewall = true;
            };
          };

          # --- nzbget

          nzbget = {
            enable = true;
            user = "root";
            group = "root";
          };

          # --- flare solverr

          flaresolverr = {
            enable = true;
            port = 8191;
            openFirewall = true;
          };
        };
        networking = {
          hostName = "torrents";
          firewall.allowedTCPPorts = [ 6789 ];
        };
      };
    };

    # ============================= Proxy =============================

  };
}
