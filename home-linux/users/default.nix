{
  homeDirectory,
  username,
  pkgs,
  ...
}:
{
  imports = [
    ../modules/packages.nix
    ../modules/git.nix
    ../modules/gh.nix
    ../modules/shell.nix
    (import ../../modules/tmux.nix {
      shell = "${pkgs.zsh}/bin/zsh";
      # Wayland / X11 をセッション環境から実行時判定してクリップボードへコピーする。
      copyCommand = ''if [ -n "$WAYLAND_DISPLAY" ]; then wl-copy; else xclip -selection clipboard -in; fi'';
    })
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
