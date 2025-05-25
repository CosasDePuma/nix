{ lib, ... }: {
  imports = lib.pipe (lib.fileset.fileFilter (file: lib.strings.hasSuffix ".nix" file.name) ./.) [
      lib.fileset.toList
      (builtins.filter (path: path != ./. + "/default.nix"))
    ];
}