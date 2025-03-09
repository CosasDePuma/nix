{ config, options, lib, pkgs, namespace, ... }: {
  options."${namespace}".services.docker = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Docker support.";
    };

    rootless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable rootless mode for Docker.";
    };
  };

  config = {
    assertions = [{
      assertion = config.virtualisation.podman.enable != true;
      msg = "Podman and Docker cannot both be enabled at the same time.";
    }];

    system.activationScripts = lib.mkIf config."${namespace}".services.docker.enable {
      "oci-defaults-network".text = lib.mkDefault ''
        ${pkgs.docker}/bin/docker network inspect defaults >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create --subnet=172.18.100.0/24 defaults 
      '';
    };

    virtualisation = lib.mkIf config."${namespace}".services.docker.enable {
      docker.enable = lib.mkDefault true;
      docker.enableOnBoot = lib.mkDefault true;
      docker.rootless = lib.mkIf config."${namespace}".services.docker.rootless {
        enable = lib.mkDefault true;
        setSocketVariable = lib.mkDefault true;
      };
      docker.autoPrune.enable = true;
      docker.autoPrune.dates = "daily";
      docker.autoPrune.flags = [ "--all" "--force" "--volumes" ];
      oci-containers.backend = lib.mkDefault "docker";
    };
  };
}