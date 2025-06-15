let
  nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos";
  vm-wonderland = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE8BS7ZkNLC4EpAfTDzFi2XVyqHtbw0w/G/keAxq9NAW @wonderland";
in
{
  # arkham
  "systems/x86_64-linux/wonderland/secrets/acme.env.age".publicKeys = [
    nixos
    vm-wonderland
  ];
  "systems/x86_64-linux/wonderland/secrets/ddclient.token.age".publicKeys = [
    nixos
    vm-wonderland
  ];
  "systems/x86_64-linux/wonderland/secrets/smb-credentials.age".publicKeys = [
    nixos
    vm-wonderland
  ];
  "systems/x86_64-linux/wonderland/secrets/vaultwarden-passwd.age".publicKeys = [
    nixos
    vm-wonderland
  ];
}
