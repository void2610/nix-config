{ pkgs, ... }:

{
  # ホームディレクトリとユーザー名
  home.username = "shuya";
  home.homeDirectory = "/Users/shuya";

  # home-manager のバージョン
  home.stateVersion = "24.11";

  # --- インストールするパッケージ（将来 Homebrew から移行するもの） ---
  home.packages = with pkgs; [
    # 現時点では最小限（徐々に移行予定）
  ];

  # home-manager 自身による管理を有効化
  programs.home-manager.enable = true;
}
