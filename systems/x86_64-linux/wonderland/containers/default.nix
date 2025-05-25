_: _: {
  virtualisation = {
    oci-containers.backend = "podman";               # Use Podman as the backend for OCI containers
    podman = {
      enable = true;                                 # Enable Podman
      dockerCompat = true;                           # Enable Docker compatibility
      dockerSocket.enable = true;                    # Enable Docker socket
      autoPrune = {
        enable = true;                               # Enable automatic pruning
        dates = "daily";                             # Interval for pruning
        flags = [ "--all" "--volumes" "--force" ];   # Options for pruning
      };
    };
  };
}