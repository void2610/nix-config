{
  imports = [
    ../modules/defaults.nix
    ../modules/homebrew.nix
    ../modules/security.nix
    ../modules/nix-core.nix
    ../modules/secrets.nix
  ];

  networking.hostName = "Macintosh";

  system.primaryUser = "shuya";

  users.users.shuya = {
    name = "shuya";
    home = "/Users/shuya";
  };
}
