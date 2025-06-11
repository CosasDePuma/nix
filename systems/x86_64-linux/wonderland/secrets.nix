{
  config ? throw "no imported as a module",
  lib ? "no imported as a module",
  ...
}:
lib.mkIf (config ? "age") {
  age = {
    identityPaths = builtins.map (key: key.path) config.services.openssh.hostKeys;
    secrets =
      let
        mkSecret = file: {
          inherit file;
          owner = "root";
          group = "root";
          mode = "0400";
        };
      in
      {
        "acme-token" = mkSecret ./secrets/acme-token.age;
        "ddclient-token" = mkSecret ./secrets/ddclient-token.age;
        "smb-credentials" = mkSecret ./secrets/smb-credentials.age;
        "vaultwarden-passwd" = mkSecret ./secrets/vaultwarden-passwd.age;
      };
  };
}
