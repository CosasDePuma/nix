{ nixpkgs, ... }:
let
  inherit (nixpkgs) lib;
in
{
  # Generate attributes for all supported systems
  forEachSystem =
    supportedSystems: fn:
    lib.genAttrs supportedSystems (
      system:
      fn {
        inherit system;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      }
    );

  # Import all nix files from a given directory
  import' =
    dir: args:
    lib.pipe (builtins.readDir dir) [
      (lib.attrsets.filterAttrs (name: type: (type == "regular") && (lib.strings.hasSuffix ".nix" name)))
      lib.attrNames
      (builtins.map (file: {
        name = lib.strings.removeSuffix ".nix" file;
        value = import "${dir}/${file}" args;
      }))
      builtins.listToAttrs
    ];
}
