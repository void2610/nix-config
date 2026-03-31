{ ... }:

{
  homebrew = {
    enable = true;

    onActivation.cleanup = "zap";
    global.autoUpdate = false;

    brews = [
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

    casks = [
      "affinity"
      "alt-tab"
      "appcleaner"
      "arc"
      "bitwarden"
      "claude-code"
      "codex"
      "discord"
      "displaylink"
      "github"
      "hiddenbar"
      "karabiner-elements"
      "keycastr"
      "linearmouse"
      "notchnook"
      "obs"
      "orbstack"
      "raycast"
      "rider"
      "sf-symbols"
      "spotify"
      "steam"
      "tailscale-app"
      "the-unarchiver"
      "typeless"
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
