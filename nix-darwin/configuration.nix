{ pkgs, ... }:

{
  # homebrew.nix を読み込む
  imports = [ ./homebrew.nix ];

  # ホスト名
  networking.hostName = "Macintosh";

  # プライマリユーザー（nix-darwin のユーザー固有設定に必要）
  system.primaryUser = "shuya";

  # ユーザー設定（home-manager が homeDirectory を正しく取得するために必要）
  users.users.shuya = {
    name = "shuya";
    home = "/Users/shuya";
  };

  # -----------------------------------------------------------------------
  # macOS システム設定
  # -----------------------------------------------------------------------
  system.defaults = {

    # --- Dock ---
    dock = {
      autohide = true;                      # Dock を自動的に隠す
      autohide-delay = 0.0;                 # 表示遅延をなくす
      autohide-time-modifier = 0.4;         # アニメーション速度
      magnification = true;                 # アイコン拡大を有効化
      largesize = 62;                       # 拡大時のサイズ
      tilesize = 59;                        # 通常時のサイズ
      mineffect = "scale";                  # 最小化アニメーション: スケール
      minimize-to-application = false;      # アプリアイコンに最小化しない
      launchanim = true;                    # アプリ起動アニメーション
      show-process-indicators = true;       # 実行中アプリのインジケータ表示
      show-recents = false;                 # 最近使ったアプリを表示しない
      mru-spaces = false;                   # スペースを最近使用した順に並べない
      expose-group-apps = true;             # Mission Control でアプリごとにグループ化
      # ジェスチャー設定
      showMissionControlGestureEnabled = true;   # Mission Control ジェスチャー有効
      showAppExposeGestureEnabled = false;       # App Exposé ジェスチャー無効
      showDesktopGestureEnabled = false;         # デスクトップ表示ジェスチャー無効
      showLaunchpadGestureEnabled = false;       # Launchpad ジェスチャー無効
      # ホットコーナー
      wvous-tl-corner = 2;   # 左上: Mission Control
      wvous-tr-corner = 2;   # 右上: Mission Control
      wvous-bl-corner = 11;  # 左下: Launchpad
      wvous-br-corner = 4;   # 右下: デスクトップ
    };

    # --- Finder ---
    finder = {
      AppleShowAllFiles = true;              # 隠しファイルを表示
      AppleShowAllExtensions = true;         # 常にファイル拡張子を表示
      ShowPathbar = true;                    # パスバーを表示
      ShowStatusBar = true;                  # ステータスバーを表示
      FXPreferredViewStyle = "Nlsv";         # デフォルト表示: リスト
      FXEnableExtensionChangeWarning = false; # 拡張子変更時の警告を無効化
      QuitMenuItem = true;                   # Finder をメニューから終了可能に
      _FXSortFoldersFirst = true;            # フォルダを先頭にソート
      _FXSortFoldersFirstOnDesktop = true;   # デスクトップでもフォルダを先頭に
      _FXShowPosixPathInTitle = false;       # タイトルバーに POSIX パスを表示しない
    };

    # --- グローバル設定 ---
    NSGlobalDomain = {
      # 外観
      AppleInterfaceStyle = "Dark";          # ダークモード
      AppleShowScrollBars = "Automatic";     # スクロールバー: 自動
      _HIHideMenuBar = false;                # メニューバーを常に表示
      AppleWindowTabbingMode = "always";     # 常にタブで開く

      # ファイル・拡張子
      AppleShowAllExtensions = true;         # 常にファイル拡張子を表示

      # キーボード
      ApplePressAndHoldEnabled = false;      # キーリピートを有効化（長押し入力を無効化）
      InitialKeyRepeat = 15;                 # キーリピート開始までの時間
      KeyRepeat = 2;                         # キーリピート速度
      AppleKeyboardUIMode = 3;               # フルキーボードアクセスを有効化

      # トラックパッド・スクロール
      "com.apple.trackpad.forceClick" = true;        # フォースクリック有効
      "com.apple.trackpad.scaling" = 3.0;            # トラックパッド速度
      "com.apple.swipescrolldirection" = true;        # スクロール方向: 自然

      # テキスト入力
      NSAutomaticCapitalizationEnabled = true;        # 自動大文字化
      NSAutomaticDashSubstitutionEnabled = true;      # ダッシュ自動置換
      NSAutomaticPeriodSubstitutionEnabled = false;   # ピリオド自動挿入を無効化
      NSAutomaticQuoteSubstitutionEnabled = true;     # 引用符自動置換
      NSAutomaticSpellingCorrectionEnabled = true;    # スペル自動修正

      # 単位
      AppleMeasurementUnits = "Centimeters"; # 測定単位: センチメートル
      AppleMetricUnits = 1;                  # メートル法を使用
      AppleTemperatureUnit = "Celsius";      # 温度単位: 摂氏
    };

    # --- スクリーンショット ---
    screencapture = {
      location = "~/Downloads";  # 保存先: ダウンロード
      target = "file";           # ファイルとして保存
      disable-shadow = false;    # ドロップシャドウを残す
      include-date = true;       # ファイル名に日時を含める
      show-thumbnail = true;     # サムネイルを表示
    };

    # --- メニューバー時計 ---
    menuExtraClock = {
      FlashDateSeparators = false;  # コロンの点滅なし
      IsAnalog = false;             # デジタル表示
      Show24Hour = true;            # 24 時間形式
      ShowDate = 1;                 # 日付を表示
      ShowDayOfMonth = true;        # 日を表示
      ShowDayOfWeek = true;         # 曜日を表示
      ShowSeconds = false;          # 秒は表示しない
    };

    # --- スペース ---
    spaces = {
      spans-displays = false; # ディスプレイごとに独立したスペース
    };

    # --- スクリーンセーバー ---
    screensaver = {
      askForPassword = true;   # スクリーンセーバー解除時にパスワードを要求
      askForPasswordDelay = 0; # 即座にパスワードを要求
    };
  };

  # -----------------------------------------------------------------------
  # セキュリティ設定
  # -----------------------------------------------------------------------

  # Touch ID で sudo を許可
  security.pam.services.sudo_local.touchIdAuth = true;

  # -----------------------------------------------------------------------
  # Nix 設定
  # -----------------------------------------------------------------------
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # システムバージョン（変更不要）
  system.stateVersion = 6;
}
