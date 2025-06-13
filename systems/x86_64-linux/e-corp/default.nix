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

    device = "/dev/nvme0n1";
    dnsProvider = "cloudflare";
    domain = "hackr.es";
    ipv4 = "51.159.16.208";
    safeDir = "/persist";
    userdesc = "Hello, friend.";
    username = "elliot";
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
