{ profile, config, pkgs, ... }:
let
  commonBrews = [
    # macOS には GNU coreutils の timeout が無いため、単体実装を入れる
    "aisk/tap/timeout"
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
    "yazi"
    "zellij"
    "zlib"
    "zoxide"
  ];

  commonTaps = [
    "aisk/tap"
  ];

  commonCasks = [
    "battery"
    "bitwarden"
    "claude-code@latest"
    "codex"
    "font-jetbrains-mono-nerd-font"
    "font-plemol-jp-nf"
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

  # Melchior 関連プロジェクトの依存
  melchiorBrews = [
    "python@3.12"
    "pinocchio"
    "coal"
    "cmake"
    "pkg-config"
    "make"
    "boost"
    "assimp"
    "opencv@4"
    "vulkan-loader"
    "vulkan-headers"
    "molten-vk"
    "glfw"
    "glew"
    "freetype"
    "glm"
    "vtk"
    "flann"
    "pcl"
    "bullet"
    "lcov"
    "tracy"
    "apache-arrow"
    # Taskfile の `task pylint` が呼ぶ Python 静的解析。CI と同じ検査をローカルで再現するために必要
    "pyright"
    "ruff"
  ];

  # Docker daemon のローカル環境。
  # Docker Desktop は業務利用ライセンスが面倒なため、Lima ベースの colima で代替する。
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
      # Unity YAML のセマンティック diff CLI (lazygit の externalDiffCommand から使用)
      brews = [ "hashiiiii/tap/prefablens" ];
      casks = desktopCasks ++ [
        "affinity"
        "discord"
        "obs"
        "rider"
        "sf-symbols"
        # Windows 版 Steam ゲーム用 Wine ラッパー (Wineskin/Kegworks 後継)。要 Rosetta 2。
        "sikarugir-app/sikarugir/sikarugir"
        "steam"
        "typeless"
        "unity-hub"
      ];
      masApps = desktopMasApps;
      taps = [
        "hashiiiii/tap"
        "sikarugir-app/sikarugir"
      ];
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
        "tigervnc"
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
    profiles.${profile}
      or (throw "homebrew.nix: 未知の profile \"${profile}\" です (有効: ${toString (builtins.attrNames profiles)})");
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
    taps = commonTaps ++ selected.taps;
  };

  # 非公式 tap の trust 登録を宣言管理する。Homebrew が trust.json を書き戻す際に nix store へのリンクを拒否するため、リンクでなく実ファイルとしてコピー配置する。
  home-manager.users.${config.system.primaryUser} =
    { lib, ... }:
    let
      trustJson = pkgs.writeText "trust.json" (
        builtins.toJSON { trustedtaps = map (tap: tap.name) config.homebrew.taps; }
      );
    in
    {
      home.activation.homebrewTrustStore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -Dm600 ${trustJson} "$HOME/.homebrew/trust.json"
      '';
    };
}
