_: {
  system = {
    autoUpgrade = {
      enable = true;                      # Enable auto-upgrades
      flake = "github:cosasdepuma/nix";   # Flake to use for auto-upgrades
      dates = "daily";                    # Daily checks for updates
      operation = "switch";               # Switches to the new system immediately
      persistent = true;                  # Ensures that auto-upgrades are executed
    };
    stateVersion = "25.05";               # NixOS state version
  };
}