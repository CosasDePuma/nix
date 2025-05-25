_: { config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ cifs-utils ];

  systemd.tmpfiles.rules = lib.pipe config.fileSystems [
    (lib.mapAttrsToList (path: _: lib.optional (lib.hasPrefix "/mnt" path)  "d ${path} 0700 0 0 -" ))
    lib.flatten
  ];

  fileSystems = builtins.listToAttrs (map (share: {
    name = "/mnt/${lib.strings.toLower share}";
    value = {
      device = "//192.168.1.3/${share}";
      fsType = "cifs";
      options = [
        "credentials=/run/agenix/smb-credentials"
        "nofail"
        "x-systemd.automount"
        "x-systemd.mount-timeout=10m"
      ];
    };
  }) [ "Backups" "Media" ]);
}