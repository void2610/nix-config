{ pkgs, ... }:
let
  homeDir = "/Users/shuya";
  neofetch = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "neofetch";
    version = "7.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "dylanaraps";
      repo = "neofetch";
      rev = version;
      hash = "sha256-ewLgOFTmUyl8JV/lpYmtwQuC43pR/SuMBPPzG3W8/EQ=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 neofetch "$out/bin/neofetch"
      install -Dm644 neofetch.1 "$out/share/man/man1/neofetch.1"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Command-line system information tool written in bash";
      homepage = "https://github.com/dylanaraps/neofetch";
      license = licenses.mit;
      mainProgram = "neofetch";
      platforms = platforms.unix;
    };
  };
in
{
  # ホームディレクトリとユーザー名
  home.username = "shuya";
  home.homeDirectory = homeDir;

  # home-manager のバージョン
  home.stateVersion = "24.11";

  # --- インストールするパッケージ（将来 Homebrew から移行するもの） ---
  home.packages = with pkgs; [
    dotnet-sdk # Unity プロジェクトのフォーマットチェックで使用
    neofetch
  ];

  home.sessionPath = [
    "/Applications/platform-tools"
    "${homeDir}/Documents"
    "${homeDir}/.local/bin"
    "${homeDir}/.yarn/bin"
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
  };

  xdg.configFile."starship.toml".source = ./starship.toml;

  programs.git = {
    enable = true;
    signing.format = "openpgp";
    ignores = [
      "**/.claude/settings.local.json"
      ".DS_Store"
    ];
    settings = {
      user = {
        name = "void2610";
        email = "contact@void2610.dev";
      };
      alias = {
        unstage = "reset HEAD";
      };
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
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

  # home-manager 自身による管理を有効化
  programs.home-manager.enable = true;
}
