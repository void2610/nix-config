{ lib, profile, ... }:
let
  commonBrews = [
    "eza"
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
    "github"
    "hiddenbar"
    "karabiner-elements"
    "keycastr"
    "linearmouse"
    "orbstack"
    "raycast"
    "spotify"
    "tailscale-app"
    "the-unarchiver"
    "visual-studio-code"
    "warp"
    "zed"
  ];

  profileBrews =
    {
      game = [ ];
      work = [ ];
      server = [ ];
    }.${profile} or [ ];

  profileCasks =
    {
      game = [
        "affinity"
        "discord"
        "obs"
        "rider"
        "sf-symbols"
        "steam"
        "typeless"
        "unity-hub"
      ];
      work = [
      ];
      server = [
        "unity-hub"
      ];
    }.${profile} or [ ];

  desktopMasApps = {
    "Amphetamine" = 937984704;
    "RunCat" = 1429033973;
  };

  profileMasApps =
    {
      game = desktopMasApps;
      work = desktopMasApps;
      server = {
        "Amphetamine" = 937984704;
      };
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
