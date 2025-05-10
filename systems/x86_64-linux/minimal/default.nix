{ namespace, ... }: {
  "${namespace}".hardware.devices = [ "/dev/sda" ];
  system.stateVersion = "25.05";
  networking.hostName = "minimal";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ]; 
  users.users."root".initialPassword = "nixos";
  services.openssh = { enable = true; openFirewall = true; settings.PermitRootLogin = "yes"; };
}