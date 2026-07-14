{ pkgs, ... }:
let
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
  home.packages = with pkgs; [
    # mac 側 home-manager/modules/packages.nix のクロスプラットフォーム分
    age
    clang-tools
    cmake
    delta
    fd
    gh
    gh-dash
    ghostscript
    ghq
    go-task
    imagemagick
    lazygit
    mermaid-cli
    neofetch
    neovim
    nodejs_22
    qemu
    sops
    tectonic
    tree-sitter
    yarn

    # mac 側 Homebrew formulae (commonBrews) の nixpkgs 代替
    bat
    cargo
    eza
    ffmpeg
    git-lfs
    go
    jq
    just
    ninja
    openssl
    pet
    pnpm
    ripgrep
    rustc
    uv
    yazi
    zlib

    # terminal-notifier 代替の通知 CLI (notify-send)
    libnotify

    # tmux copy-mode 用クリップボード (Wayland / X11)
    wl-clipboard
    xclip

    # Homebrew cask font-jetbrains-mono-nerd-font の代替
    nerd-fonts.jetbrains-mono
  ];
}
