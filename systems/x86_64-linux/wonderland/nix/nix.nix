_: {
  boot.readOnlyNixStore = true;            # Make the Nix store read-only to prevent modifications
  nix = {
      gc = {
      automatic = true;                    # Enable automatic garbage collection
      dates = "weekly";                    # Weekly removes old packages and generations
      options = "--delete-older-than 7d";  # Removes everything older than 7 days
      persistent = true;                   # Ensures that garbage collection is executed
    };
    settings = {
      allowed-users = [ "@wheel" ];        # Only allow users in the wheel group to access the Nix store
    };
  };
}