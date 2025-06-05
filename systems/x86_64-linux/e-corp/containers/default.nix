_: { config, pkgs, ... }: {
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

  system.activationScripts."oci-containers-networks".text = let 
    backend = config.virtualisation.oci-containers.backend;
  in ''
    #!/bin/sh
    # Create the OCI containers networks
    ${pkgs.${backend}}/bin/${backend} network create --subnet=172.20.0.0/24 public || :
  '';
}