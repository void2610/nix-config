# Melchior開発用Pythonパッケージ定義
# Melchior/toadflax は C++ 側で Python を埋め込んで起動するため、
# nix で入れた Python パッケージがあっても通常の import 探索だけでは
# site-packages を見つけられないことがある。
# そのため、Melchior から直接使う Python 依存を 1 つの env にまとめ、
# terminal から起動する時に同じ site-packages を確実に見せる。
{ pkgs, ... }:
let
  # toadflax や関連 addon が実行時 import するパッケージ群。
  # Melchior 本体の build-time dependency ではなく、実行時の埋め込み Python 向け。
  melchiorPython = pkgs.python312.withPackages (ps: with ps; [
    numpy
    scipy
    ezdxf
    shapely
    numba
    requests
    tqdm
    matplotlib
    tensorboard
    laspy
    coverage
    pyproj
    staticmap
    opencv-python
  ]);

  # terminal から Melchior 開発環境へ入るためのラッパー。
  # ここで PYTHONPATH を固定してから repo に移動することで、
  # `./build/melchior_main` をどのシェルから起動しても
  # nix 側の Python パッケージを同じ形で参照できるようにする。
  melchiorDev = pkgs.writeShellScriptBin "melchior-dev" ''
    export PYTHONPATH="${melchiorPython}/${melchiorPython.sitePackages}${PYTHONPATH:+:$PYTHONPATH}"
    cd "$HOME/Documents/GitHub/melchior"
    exec "''${SHELL:-/bin/zsh}" -i
  '';
in
{
  home.packages = [
    melchiorPython
    melchiorDev
  ];

  # 普段のログインシェルでも同じ PYTHONPATH を使う。
  # `melchior-dev` を経由しない起動でも import 解決を揃えるため。
  home.sessionVariables.PYTHONPATH =
    "${melchiorPython}/${melchiorPython.sitePackages}";
}
