# Melchior開発用Pythonパッケージ定義
{ pkgs, ... }:
let
  melchiorPython = pkgs.python312.withPackages (ps: with ps; [
    numpy
    scipy
    ezdxf
    shapely
    numba
  ]);
in
{
  home.packages = [ melchiorPython ];

  # 埋め込みPythonがnixパッケージを認識できるよう設定
  home.sessionVariables.PYTHONPATH =
    "${melchiorPython}/lib/python3.12/site-packages";
}
