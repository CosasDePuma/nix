{ pkgs, inputs, system, ... }: with pkgs; mkShell {
  name = "nixos";
  NIX_CONFIG = "experimental-features = flakes nix-command pipe-operators";
  buildInputs = [
    deadnix                                           # dead code scanner
    nh                                                # yet another nix cli wrapper
    nixos-anywhere                                    # nixos installation over ssh
    nixos-rebuild                                     # nixos configuration rebuild
    statix                                            # nixos configuration linter

    inputs.agenix.packages.${system}.default          # secret management
    inputs.darwin.packages.${system}.default          # darwin configuration rebuild
  ];
  shellHook = ''
    help() {
      echo 
      echo "+--------------------+"
      echo "| Available commands |"
      echo "+--------------------+"
      echo 
      echo "agenix             |> secret management"
      echo "darwin-rebuild     |> darwin configuration rebuild"
      echo "deadnix            |> dead code scanner"
      echo "nh                 |> yet another nix cli wrapper"
      echo "nixos-anywhere     |> nixos installation over ssh"
      echo "nixos-rebuild      |> nixos configuration rebuild"
      echo "statix             |> nixos configuration linter"
      echo
    }
    clear && help
  '';
}
