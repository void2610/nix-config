{ pkgs, ... }:

{
  # homebrew.nix を読み込む
  imports = [ ./homebrew.nix ];

  # ホスト名
  networking.hostName = "Macintosh";

  # --- macOS システム設定 ---
  system.defaults = {
    # Dock の設定
    dock = {
      autohide = true;               # Dock を自動的に隠す
      show-recents = false;          # 最近使ったアプリを表示しない
      tilesize = 48;                 # Dock のサイズ
    };

    # Finder の設定
    finder = {
      AppleShowAllFiles = true;      # 隠しファイルを表示
      ShowPathbar = true;            # パスバーを表示
      ShowStatusBar = true;          # ステータスバーを表示
      FXPreferredViewStyle = "Nlsv"; # リスト表示をデフォルトに
    };

    # スクリーンショットの保存先
    screencapture = {
      location = "~/Desktop";
    };

    # キーリピートの速度設定
    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      ApplePressAndHoldEnabled = false; # キーリピートを有効化
    };
  };

  # Touch ID で sudo を許可
  security.pam.services.sudo_local.touchIdAuth = true;

  # Nix 設定
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # システムバージョン（変更不要）
  system.stateVersion = 6;
}
