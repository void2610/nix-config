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
    dotnet-sdk
    neofetch
  ];
}
