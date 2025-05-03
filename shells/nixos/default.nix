{ pkgs, inputs, system, ... }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [
    nh                                                # yet another nix cli wrapper
    nixos-anywhere                                    # nixos installation over ssh
    nixos-rebuild                                     # nixos configuration rebuild

    inputs.agenix.packages.${system}.default          # secret management
    inputs.darwin.packages.${system}.default          # darwin configuration rebuild
    inputs.snowfall-frost.packages.${system}.default  # flake documentation generator
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
      echo "frost              |> flake documentation generator"
      echo "nh                 |> yet another nix cli wrapper"
      echo "nixos-anywhere     |> nixos installation over ssh"
      echo "nixos-rebuild      |> nixos configuration rebuild"
      echo
    }
  '';
}