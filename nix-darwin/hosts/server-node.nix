{
  imports = [
    ../modules/base.nix
    ../modules/homebrew.nix
  ];

  networking.hostName = "server-node";

  system.primaryUser = "shuya";

  users.users.shuya = {
    name = "shuya";
    home = "/Users/shuya";
  };
}
