{ ... }:

{
  homebrew = {
    enable = true;

    # 未登録パッケージの自動アンインストール
    onActivation.cleanup = "zap";
    # brew コマンド実行時の自動更新を無効化（Nix で管理）
    global.autoUpdate = false;

    brews = [
      "eza"
      "ffmpeg"
      "fzf"
      "go"
      "jq"
      "mas"
      "openssl@3"
      "pet"
      "ripgrep"
      "terminal-notifier"
      "uv"
      "zlib"
      "zoxide"
    ];

    casks = [
      "affinity"
      "alt-tab"
      "appcleaner"
      "arduino-ide"
      "arc"
      "bitwarden"
      "claude-code"
      "devpod"
      "discord"
      "displaylink"
      "github"
      "google-chrome"
      "hiddenbar"
      "keycastr"
      "linearmouse"
      "notchnook"
      "obs"
      "orbstack"
      "raycast"
      "rider"
      "spotify"
      "steam"
      "the-unarchiver"
      "unity-hub"
      "visual-studio-code"
      "warp"
      "zed"
    ];

    masApps = {
      "Amphetamine" = 937984704;
      "RunCat" = 1429033973;
    };
  };
}
