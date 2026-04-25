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
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
    # zsh-syntax-highlighting が末尾に必要なため zoxide は末尾に置けない。
    # 誤検知となる doctor 警告を無効化する。
    _ZO_DOCTOR = "0";
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
    options = [ "--cmd" "cd" ];
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ur = "uv run python";
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
    '';
  };
}
