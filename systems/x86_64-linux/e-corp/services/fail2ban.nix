_: _: {
  services.fail2ban = {
    enable = true;                          # Enable the Fail2Ban service
    maxretry = 3;                           # Maximum number of failed attempts
    bantime = "1h";                         # Ban time (1 hour)
    bantime-increment.enable = true;        # Enable incremental ban time
    bantime-increment.factor = "24";        # Increment factor (1h, 1d, 24d, 1,5y, 37y, ...)
    banaction = "%(banaction_allports)s";   # Ban access to all ports
  };
}