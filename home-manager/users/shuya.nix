{
  imports = [
    ../modules/packages.nix
    ../modules/git.nix
    ../modules/shell.nix
    ../modules/tmux.nix
  ];

  home.username = "shuya";
  home.homeDirectory = "/Users/shuya";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
