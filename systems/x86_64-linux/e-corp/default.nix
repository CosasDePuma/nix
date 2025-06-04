{ lib, ... }: let options = {
  dnsProvider = "cloudflare";
  domain      = "hackr.es";
  safeDir     = "/persist";
}; in {
  imports = lib.pipe (lib.fileset.fileFilter (file: lib.strings.hasSuffix ".nix" file.name) ./.) [
    lib.fileset.toList
    (builtins.filter (path: path != ./. + "/default.nix"))
    (builtins.map (path: import path options))
  ];
}