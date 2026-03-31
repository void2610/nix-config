{
  imports = [
    ../modules/base.nix
    ../modules/homebrew.nix
  ];

  networking.hostName = "game-dev";

  system.primaryUser = "shuya";

  users.users.shuya = {
    name = "shuya";
    home = "/Users/shuya";
  };
}
