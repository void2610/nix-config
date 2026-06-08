{ profile, ... }:
let
  commonBrews = [
    "bat"
    "eza"
    "ninja"
    "ffmpeg"
    "fzf"
    "go"
    "git-lfs"
    "jq"
    "just"
    "mas"
    "openssl@3"
    "pet"
    "pnpm"
    "poetry"
    "ripgrep"
    "rust"
    "terminal-notifier"
    "uv"
    "zlib"
    "zoxide"
  ];

  commonCasks = [
    "battery"
    "bitwarden"
    "claude-code@latest"
    "codex"
    "font-jetbrains-mono-nerd-font"
    "ghostty"
    "karabiner-elements"
    "linearmouse"
  ];

  desktopCasks = commonCasks ++ [
    "alt-tab"
    "appcleaner"
    "arc"
    "displaylink"
    "github"
    "hiddenbar"
    "keycastr"
    "raycast"
    "spotify"
    "tailscale-app"
    "the-unarchiver"
    "visual-studio-code"
    "warp"
    "zed"
  ];

  # Melchior (https://github.com/AKARI-Inc/melchior) の macOS ビルド依存。
  # docs/1.1.build.md の手順で必要になる C++ ライブラリと Python 3.12 を宣言し、
  # `darwin-rebuild switch` の cleanup=zap で消えないように永続化する。
  # jsoncpp は VTK と噛み合わない版しか brew に無いため、ソースから入れる想定で含めない。
  melchiorBrews = [
    "python@3.12"
    "pinocchio"
    "coal"
    "cmake"
    "pkg-config"
    "make"
    "boost"
    "assimp"
    "opencv"
    "glfw"
    "glew"
    "freetype"
    "glm"
    "vtk"
    "flann"
    "pcl"
    "bullet"
    "lcov"
  ];

  # Docker daemon のローカル環境。
  # Docker Desktop は業務利用ライセンスが面倒なため、Lima ベースの colima で代替する。
  # CI (kalmia-robot-learning の .github/workflows/lint.yml の build ジョブ) は docker/build-push-action で buildx を使うため、
  # 手元でも `docker buildx build` を同じ形で回して Dockerfile を事前検証できるよう CLI と buildx プラグインを同梱する。
  dockerBrews = [
    "colima"
    "docker"
    "docker-buildx"
    "shellcheck"
  ];

  workOnlyBrews = [
    "awscli"
  ];

  commonMasApps = {
    "Amphetamine" = 937984704;
  };

  desktopMasApps = commonMasApps // {
    "RunCat" = 1429033973;
  };

  # プロファイルごとの brews / casks / masApps / taps をまとめて宣言する。
  # 末尾の selector がここから profile に対応する 1 エントリを引く。
  profiles = {
    game = {
      brews = [ ];
      casks = desktopCasks ++ [
        "affinity"
        "discord"
        "obs"
        "rider"
        "sf-symbols"
        "steam"
        "typeless"
        "unity-hub"
      ];
      masApps = desktopMasApps;
      taps = [ ];
    };

    work = {
      brews = melchiorBrews ++ dockerBrews ++ workOnlyBrews;
      casks = desktopCasks ++ [
        "blender"
        "cloudcompare"
        "freecad"
        "firefox"
        "google-chrome"
        "session-manager-plugin"
        "zoom"
      ];
      masApps = desktopMasApps;
      taps = [ ];
    };

    # server は GUI 版 Tailscale ではなく nix-darwin 管理の tailscaled に切り替える。
    # sandbox 制約で Tailscale SSH を受けられないため、cask から外して競合も避ける。
    server = {
      brews = [ ];
      casks = commonCasks ++ [
        "element"
        "unity-hub"
      ];
      masApps = commonMasApps;
      taps = [ ];
    };
  };

  selected =
    profiles.${profile} or (throw "homebrew.nix: 未知の profile \"${profile}\" です (有効: ${toString (builtins.attrNames profiles)})");
in
{
  homebrew = {
    enable = true;

    # darwin-rebuild 実行時に Homebrew 側の cask と formula も更新し、
    # latest チャンネルを追う claude-code@latest を手動の brew upgrade なしで最新化するため有効にする。
    onActivation.cleanup = "zap";
    # Homebrew の宣言状態を再適用するたびに更新確認も走らせ、
    # brew 管理パッケージだけ古いまま残る運用ズレを防ぐため有効にする。
    onActivation.upgrade = true;
    # Homebrew の自動更新はログイン時などに勝手に走らせず、
    # darwin-rebuild のタイミングに更新契機を寄せて挙動を読みやすくする。
    global.autoUpdate = false;

    brews = commonBrews ++ selected.brews;
    casks = selected.casks;
    masApps = selected.masApps;
    taps = selected.taps;
  };
}
