{ config, pkgs, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  home.sessionPath = [
    "${homeDir}/.local/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "${homeDir}/Documents"
    "${homeDir}/.yarn/bin"
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
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

      # zoxideは他のツールより後に初期化する必要があるため末尾に配置
      eval "$(zoxide init zsh --cmd cd)"
    '';
  };
}
