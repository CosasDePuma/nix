{ config, lib, inputs, ... }:
  lib.optionalAttrs (builtins.hasAttr "ragenix" inputs) {
    imports = [ inputs.ragenix.nixosModules.default ];

    config = {
      age.identityPaths = lib.mkDefault (lib.optionals
        ((builtins.length config.services.openssh.hostKeys) != 0)
          (builtins.map (x: x.path) (config.services.openssh.hostKeys)));
    };
  }