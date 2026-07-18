{ config, pkgs, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  home.sessionPath = [
    "${homeDir}/.cargo/bin"
    "${homeDir}/.local/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "${homeDir}/Documents"
    "${homeDir}/.yarn/bin"
    # tailscale-app(Cask)同梱の CLI を PATH に通す。formula を入れると GUI 版 daemon と衝突するため app の MacOS バイナリを使う。
    "/Applications/Tailscale.app/Contents/MacOS"
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
    # zsh-syntax-highlighting が末尾に必要なため zoxide は末尾に置けない。
    # 誤検知となる doctor 警告を無効化する。
    _ZO_DOCTOR = "0";
    EDITOR = "nvim";
    VISUAL = "nvim";
    # lazygit の設定は ~/dotfiles/.config/lazygit/config.yml で管理する。
    # macOS の lazygit はデフォルトで ~/Library/Application Support/lazygit を見るので、
    # LG_CONFIG_FILE で dotfiles 側を明示的に読み込ませる。
    LG_CONFIG_FILE = "${homeDir}/.config/lazygit/config.yml";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship.enable = true;

  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
    options = [
      "--cmd"
      "cd"
    ];
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ur = "uv run python";
      v = "nvim";
      vi = "nvim";
      sftp = "sftp -P 25288 shuya@nitfccuda.mydns.jp";
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --group-directories-first";
      tree = "eza --tree --icons";
      bell = "afplay /System/Library/Sounds/Hero.aiff";
      # macOS 25.4以降でSSHエージェントがlimactl接続をブロックする問題の回避
      colima = "SSH_AUTH_SOCK= colima";
    };
    initContent = ''
      if command -v neofetch >/dev/null 2>&1; then
        neofetch
      fi

      eval "$(uv generate-shell-completion zsh)"

      # zoxideはcompinitより後に初期化する必要がある。
      # なおhome-managerがこの後にaliasやzsh-syntax-highlightingを追加するため
      # 真の末尾にはならない。doctor警告は_ZO_DOCTOR=0で抑止済み。
      eval "$(zoxide init zsh --cmd cd)"

      # ghq + fzf launcher。実装は g.zsh に分離。
      source ${./g.zsh}

      # yazi launcher。実装は y.zsh に分離。
      source ${./y.zsh}
    '';
  };
}
