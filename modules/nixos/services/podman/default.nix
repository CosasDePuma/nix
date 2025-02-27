{ config, options, lib, namespace, ... }: {
  options.${namespace}.services.podman = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Podman support.";
    };
  };

  config = {
    assertions = [{ assertion = !config.virtualisation.docker.enable; msg = "Podman and Docker cannot both be enabled at the same time."; }];

    virtualisation = lib.mkIf config.${namespace}.services.podman.enable {
      podman.enable = lib.mkDefault true;
      podman.dockerCompat = lib.mkDefault true;
      podman.defaultNetwork.settings.dns_enabled = lib.mkDefault true;
      podman.autoPrune.enable = true;
      podman.autoPrune.dates = "daily";
      podman.autoPrune.flags = [ "--all" "--force" "--volumes" ];
      oci-containers.backend = lib.mkDefault "podman";
    };
  };
}