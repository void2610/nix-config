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
    "mas"
    "openssl@3"
    "pet"
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

  gameBrews = [ ];
  # Melchior (https://github.com/AKARI-Inc/melchior) の macOS ビルド依存。
  # docs/1.1.build.md の手順で必要になる C++ ライブラリと Python 3.12 を宣言し、
  # `darwin-rebuild switch` の cleanup=zap で消えないように永続化する。
  # jsoncpp は VTK と噛み合わない版しか brew に無いため、ソースから入れる想定で含めない。
  melchiorBrews = [
    "python@3.12"
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
  # work 限定にするのは Docker daemon を必要とするのが kalmia のコンテナビルドだけで、game/server で VM を常駐させても無駄になるため。
  dockerBrews = [
    "colima"
    "docker"
    "docker-buildx"
    "shellcheck"
  ];
  workBrews = melchiorBrews ++ dockerBrews;
  serverBrews = [ ];

  gameCasks = desktopCasks ++ [
    "affinity"
    "discord"
    "obs"
    "rider"
    "sf-symbols"
    "steam"
    "typeless"
    "unity-hub"
  ];

  workCasks = desktopCasks ++ [
    "blender"
    "cloudcompare"
    "freecad"
    "google-chrome"
    "zoom"
  ];

  # server は GUI 版 Tailscale ではなく nix-darwin 管理の tailscaled に切り替える。
  # sandbox 制約で Tailscale SSH を受けられないため、cask から外して競合も避ける。
  serverCasks = commonCasks ++ [
    "element"
    "unity-hub"
  ];

  commonMasApps = {
    # 全プロファイルで使うスリープ抑止を App Store 管理に寄せる。
    # GUI アプリ更新を Homebrew cask と混在させないため、MAS 側で統一する。
    "Amphetamine" = 937984704;
  };

  desktopMasApps = {
    "RunCat" = 1429033973;
  };

  gameMasApps = commonMasApps // desktopMasApps;
  workMasApps = commonMasApps // desktopMasApps;
  # server でも同じスリープ抑止アプリを入れて、電源維持の責務を pmset 固定値から外す。
  # profile ごとの差分を増やさずに済むよう、共通の MAS アプリ定義をそのまま使う。
  serverMasApps = commonMasApps;

  profileBrews =
    {
      game = gameBrews;
      work = workBrews;
      server = serverBrews;
    }.${profile} or [ ];

  profileCasks =
    {
      game = gameCasks;
      work = workCasks;
      server = serverCasks;
    }.${profile} or [ ];

  profileMasApps =
    {
      game = gameMasApps;
      work = workMasApps;
      server = serverMasApps;
    }.${profile} or { };
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

    brews = commonBrews ++ profileBrews;
    casks = profileCasks;
    masApps = profileMasApps;
  };
}
