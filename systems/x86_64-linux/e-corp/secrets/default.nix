_: { config, lib, inputs, ... }: {
  imports = lib.lists.optional (inputs ? "agenix") inputs.agenix.nixosModules.default;

  config = lib.mkIf (inputs ? "agenix") {
    age = {
      identityPaths = builtins.map (key: key.path) config.services.openssh.hostKeys;
      secrets = let mkSecret = file: { inherit file; owner = "root"; group = "root"; mode = "0400"; }; in {
        "acme-token"         = mkSecret ./acme-token.age;
        "ddclient-token"     = mkSecret ./ddclient-token.age;
        "vaultwarden-passwd" = mkSecret ./vaultwarden-passwd.age;
      };
    };
  };
}