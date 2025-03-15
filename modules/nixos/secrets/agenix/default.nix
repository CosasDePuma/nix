{ config, lib, inputs, ... }:
  lib.optionalAttrs (builtins.hasAttr "agenix" inputs) {
    imports = [ inputs.agenix.nixosModules.default ];
  }