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
        "acme.env" = mkSecret ./secrets/acme.env.age;
        "ddclient.token" = mkSecret ./secrets/ddclient.token.age;
        "smb.creds" = mkSecret ./secrets/smb.creds.age;
        "vaultwarden.token" = mkSecret ./secrets/vaultwarden.token.age;
      };
  };
}
