{ pkgs }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [ nh nixos-anywhere nixos-rebuild ];
  shellHook = ''
    export PS1='⛄️ \[\e[1;2m\]\w\[\e[0m\] '

    helpdev() {
      cat <<HELP

    ⛄️ NixOS Development Shell ⛄️

    $ nixos-anywhere --flake github:cosasdepuma/nix#<system> <host>
      Install NixOS on a remote host via SSH with disk partitioning.

    $ nixos-remote github:cosasdepuma/nix#<system> <host>
      Rebuild NixOS on a remote host via SSH.

    $ nix-darwin --flake github:cosasdepuma/nix#
      Change the Nix configuration on macOS.

    HELP
    }

    alias nix-darwin='nix run nix-darwin#darwin-rebuild switch --'

    nixos-remote() {
      test $# -lt 2 && { helpdev; return 1; }
      flake="$1"; shift
      host="$2"; shift
      nixos-rebuild switch --target-host "$host" --build-host "$host" --fast --use-remote-sudo --flake "$flake" $@
    }
  '';
}