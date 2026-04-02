{ profile, ... }:
let
  commonBrews = [
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
    "terminal-notifier"
    "uv"
    "zlib"
    "zoxide"
  ];

  desktopCasks = [
    "alt-tab"
    "appcleaner"
    "arc"
    "bitwarden"
    "claude-code"
    "codex"
    "displaylink"
    "github"
    "hiddenbar"
    "karabiner-elements"
    "keycastr"
    "linearmouse"
    "raycast"
    "spotify"
    "tailscale-app"
    "the-unarchiver"
    "visual-studio-code"
    "warp"
    "zed"
  ];

  gameBrews = [ ];
  workBrews = [ ];
  serverBrews = [ ];

  gameCasks = [
    "affinity"
    "discord"
    "obs"
    "rider"
    "sf-symbols"
    "steam"
    "typeless"
    "unity-hub"
  ];

  workCasks = [
    "blender"
    "cloudcompare"
    "freecad"
    "google-chrome"
    "zoom"
  ];

  serverCasks = [
    "unity-hub"
  ];

  commonMasApps = {
    "Amphetamine" = 937984704;
  };

  desktopMasApps = {
    "RunCat" = 1429033973;
  };

  gameMasApps = commonMasApps // desktopMasApps;
  workMasApps = commonMasApps // desktopMasApps;

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

    onActivation.cleanup = "zap";
    global.autoUpdate = false;

    brews = commonBrews ++ profileBrews;
    casks = desktopCasks ++ profileCasks;
    masApps = profileMasApps;
  };
}
