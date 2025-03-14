{ pkgs }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [
    # SSH
    ssh-audit
    terrapin-scanner
  ];

  shellHook = ''
    hack-ssh() {
      if test "$#" -lt 1; then
        printf "Usage: $0 <host> [port]\n" >&2
        return 1
      fi

      host="$1"
      port="$2"; if test -z "$port"; then port=22; fi

      terrapin-scanner -connect "$host:$port"
      sleep 2
      ssh-audit -p "$port" "$host"
    }
  '';
}