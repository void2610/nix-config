{ pkgs, ... }:
let
  homeDir = "/Users/shuya";
in
{
  home.sessionPath = [
    "/Applications/platform-tools"
    "${homeDir}/Documents"
    "${homeDir}/.local/bin"
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
    enableZshIntegration = true;
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
    };
    initContent = ''
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

      if [ -s "$NVM_DIR/nvm.sh" ]; then
        nvm use default --silent
      fi

      export JAVA_HOME=$(/usr/libexec/java_home -v 21)

      if command -v neofetch >/dev/null 2>&1; then
        neofetch
      fi

      eval "$(uv generate-shell-completion zsh)"
    '';
  };
}
