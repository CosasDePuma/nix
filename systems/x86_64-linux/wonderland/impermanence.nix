{ safeDir, ... }: { config, lib, ... }: {   # TODO(improvement): Create a real impermanence module
  systemd.tmpfiles.rules = lib.flatten (
    # --- oci-container volumes ---
    (lib.mapAttrsToList (_: container:
      builtins.map (volume:
        lib.optional (lib.hasPrefix safeDir volume) 
          "d ${builtins.head (lib.strings.splitString ":" volume)} 0700 998 998 -"
      ) (container.volumes or [])
    ) config.virtualisation.oci-containers.containers) ++
    # --- systemd-nspawn bind mounts ---
    (lib.mapAttrsToList (_: container:
      lib.mapAttrsToList (_: mount:
        lib.optional (lib.hasPrefix safeDir mount.hostPath) 
          "d ${mount.hostPath} 0700 999 999 -"
      ) (container.bindMounts or {})
    ) config.containers));
}