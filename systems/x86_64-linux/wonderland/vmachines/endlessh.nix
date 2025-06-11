{
  config ? throw "no imported as a module",
  ipv4 ? "ipv4 not defined",
  ...
}:
{
  containers."endlessh" = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    localAddress = "10.100.0.1";
    hostAddress = ipv4;
    forwardPorts = [
      {
        hostPort = 22;
        containerPort = config.containers."endlessh".config.services.endlessh-go.port;
      }
    ];
    config = {

      # ============================= Config =============================

      system.stateVersion = config.system.stateVersion;
      services.endlessh-go = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 22;
        openFirewall = true;
        extraOptions = [ "-geoip_supplier=ip-api" ];
        prometheus = {
          enable = true;
          listenAddress = "0.0.0.0";
          port = 2121;
        };
      };
      networking = {
        hostName = "endlessh";
        firewall.allowedTCPPorts = [
          config.containers."endlessh".config.services.endlessh-go.prometheus.port
        ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = builtins.map (
    port: port.hostPort
  ) config.containers."endlessh".forwardPorts;
}
