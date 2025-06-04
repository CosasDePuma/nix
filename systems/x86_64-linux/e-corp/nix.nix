_: _: {

  # =============================== Store ===============================

  boot.readOnlyNixStore = true;                # Make the Nix store read-only to prevent modifications
  nix = {
      gc = {
      automatic = true;                        # Enable automatic garbage collection
      dates = "weekly";                        # Weekly removes old packages and generations
      options = "--delete-older-than 7d";      # Removes everything older than 7 days
      persistent = true;                       # Ensures that garbage collection is executed
    };
    settings.allowed-users = [ "@wheel" ];     # Only allow users in the wheel group to access the Nix store
  };

  # =============================== System ===============================

  system = {
    autoUpgrade = {
      enable = true;                           # Enable auto-upgrades
      flake = "github:cosasdepuma/nix/audea";  # Flake to use for auto-upgrades
      dates = "daily";                         # Daily checks for updates
      operation = "switch";                    # Switches to the new system immediately
      persistent = true;                       # Ensures that auto-upgrades are executed
    }; 
    stateVersion = "25.05";                    # System state version for compatibility
  };
}