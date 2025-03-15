let
  nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos";
  vm-ecorp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFIyqYF7jBKgSN8cVNiv12/brfibgoDbY8Z3NBfkt/pl @e-corp";
in {
  "systems/x86_64-linux/e-corp/duckdns-token.age".publicKeys = [ nixos vm-ecorp ];
}