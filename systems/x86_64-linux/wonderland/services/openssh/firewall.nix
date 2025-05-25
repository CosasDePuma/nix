{ config, lib, ... }: {
  networking.firewall.allowedTCPPorts = builtins.map (addr: addr.port)
    config.services.openssh.listenAddresses;
}