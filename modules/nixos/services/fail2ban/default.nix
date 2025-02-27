{ config, options, lib, namespace, ... }: {
  options.${namespace}.services.fail2ban = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the fail2ban service.";
    };
  };

  config.services.fail2ban = lib.mkIf config.${namespace}.services.fail2ban.enable {
    enable = lib.mkDefault true;
    maxretry = lib.mkDefault 3;
    bantime = lib.mkDefault "1h";
    banaction = lib.mkDefault "%(banaction_allports)s";
    bantime-increment.enable = lib.mkDefault true;
    bantime-increment.factor = lib.mkDefault "24";
  };
}