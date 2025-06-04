_: _: {
  services.clamav = {
    daemon.enable = true;            # Enable the ClamAV daemon
    scanner = {
      enable = true;                 # Enable the ClamAV scanner
      interval = "*-*-* 05:00:00";   # Scan every day at 05:00AM
      scanDirectories = [ "/bin" "/etc" "/home" "/mnt" "/nix" "/root" "/srv" "/tmp" "/var" ];
    };
    fangfrisch = {
      enable = true;                 # Enable the Fangfrisch service
      interval = "hourly";           # Update the database every hour
    };
    updater = {
      enable = true;                 # Enable the ClamAV updater
      frequency = 12;                # Numbers of database updates per day
    };
  };
}