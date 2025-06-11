{
  lib ? throw "not imported as a module",
  inputs ? { },
  stateVersion ? "25.05",
  ...
}:
lib.nixosSystem {
  system = "x86_64-linux";

  specialArgs = {
    inherit inputs stateVersion;

    device = "/dev/sda";
    dnsProvider = "cloudflare";
    domain = "kike.wtf";
    ipv4 = "192.168.1.254";
    safeDir = "/persist";
    shares = [
      "//192.168.1.3/Backups"
      "//192.168.1.3/Media"
    ];
    userdesc = "Alice in Wonderland!";
    username = "alice";
  };

  modules =
    (builtins.map (input: input.nixosModules.default) (
      builtins.filter (input: input ? "nixosModules" && input.nixosModules ? "default") (
        builtins.attrValues inputs
      )
    ))
    ++ [
      ./configuration.nix
      ./containers
      ./disko.nix
      ./secrets.nix
      ./vmachines
    ];
}
