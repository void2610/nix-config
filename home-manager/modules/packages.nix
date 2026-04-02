{ pkgs, profile, ... }:
let
  claudeCodeUi = import ../../pkgs/claude-code-ui.nix { inherit pkgs; };

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
  # Melchior開発用Pythonパッケージ環境
  melchiorPython = pkgs.python312.withPackages (ps: with ps; [
    numpy
    scipy
    ezdxf
    shapely
    numba
  ]);
in
{
  home.packages = with pkgs; [
    age
    clang-tools
    cmake
    colima
    dotnet-sdk
    claudeCodeUi
    docker-client
    docker-compose
    fd
    gh
    neofetch
    neovim
    nodejs_22
    qemu
    sops
    yarn
    melchiorPython
  ];

  # 埋め込みPythonがnixパッケージを認識できるよう設定
  home.sessionVariables.PYTHONPATH =
    "${melchiorPython}/lib/python3.12/site-packages";
}
