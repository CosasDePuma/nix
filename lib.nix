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

  ## Facilita la creación de configuraciones de NixOS
  #mkNixosConfiguration = {
  #  system ? "x86_64-linux",
  #  hostname,
  #  username ? "pumita",
  #  specialArgs ? {},
  #  modules ? [],
  #  extraModules ? []
  #}:
  #  lib.nixosSystem {
  #    inherit system;
  #    specialArgs = {
  #      inherit inputs hostname username;
  #    } // specialArgs;
  #    modules = [
  #      # Módulos base comunes a todas las configuraciones
  #      ../modules/nixos/common.nix
  #      # Configuración específica del host
  #      ../hosts/${hostname}/configuration.nix
  #    ] ++ modules ++ extraModules;
  #  };
  #
  ## Facilita la creación de configuraciones de Home Manager
  #mkHomeConfiguration = {
  #  system ? "x86_64-linux",
  #  username,
  #  hostname ? null,
  #  extraModules ? []
  #}:
  #  inputs.home-manager.lib.homeManagerConfiguration {
  #    pkgs = import inputs.nixpkgs {
  #      inherit system;
  #      config.allowUnfree = true;
  #    };
  #    extraSpecialArgs = {
  #      inherit inputs system username hostname;
  #    };
  #    modules = [
  #      # Configuración común de home-manager
  #      ../modules/home-manager/common.nix
  #      # Configuración específica del usuario
  #      ../home/${username}/home.nix
  #    ] ++ extraModules;
  #  };
  #
  ## Obtiene todas las configuraciones de NixOS en la carpeta hosts
  #getSystemConfigurations = hostsPath:
  #  let
  #    hostDirs = builtins.readDir hostsPath;
  #    hostnames = builtins.attrNames hostDirs;
  #
  #    # Filtra para obtener solo directorios
  #    validHosts = builtins.filter (hostname:
  #      hostDirs.${hostname} == "directory" &&
  #      builtins.pathExists "${hostsPath}/${hostname}/configuration.nix"
  #    ) hostnames;
  #  in
  #  builtins.listToAttrs (builtins.map (hostname: {
  #    name = hostname;
  #    value = hostname;
  #  }) validHosts);
}
