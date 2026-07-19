{ config, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  home.sessionPath = [
    "${homeDir}/.cargo/bin"
    "${homeDir}/.local/bin"
    "${homeDir}/Documents"
    "${homeDir}/.yarn/bin"
  ];

  home.sessionVariables = {
    # zoxide を末尾に置けない (zsh-syntax-highlighting が末尾必須) ための doctor 誤検知警告を抑止
    _ZO_DOCTOR = "0";
    EDITOR = "nvim";
    VISUAL = "nvim";
    # lazygit の設定は ~/dotfiles/.config/lazygit/config.yml で管理する。
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
      z = "zellij";
      sftp = "sftp -P 25288 shuya@nitfccuda.mydns.jp";
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --group-directories-first";
      tree = "eza --tree --icons";
      bell = "printf '\\a'";
    };
    initContent = ''
      if command -v neofetch >/dev/null 2>&1; then
        neofetch
      fi

      eval "$(uv generate-shell-completion zsh)"

      # zoxide は compinit より後に初期化する必要がある (末尾に置けない誤検知は _ZO_DOCTOR=0 で抑止済み)
      eval "$(zoxide init zsh --cmd cd)"

      # ghq + fzf launcher。実装は g.zsh に分離。
      source ${./g.zsh}

      # yazi launcher。実装は y.zsh に分離。
      source ${./y.zsh}
    '';
  };
}
