# Melchior開発用Pythonパッケージ定義
# Melchior/toadflax は C++ 側で Python を埋め込んで起動するため、
# nix で入れた Python パッケージがあっても通常の import 探索だけでは
# site-packages を見つけられないことがある。
# そのため、Melchior から直接使う Python 依存を 1 つの env にまとめ、
# terminal から起動する時に同じ site-packages を確実に見せる。
{ pkgs, lib, ... }:
let
  melchiorRepo = "$HOME/Documents/GitHub/melchior";
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
  ]);
  melchiorSitePackages = "${melchiorPython}/${melchiorPython.sitePackages}";

  # terminal から Melchior 開発環境へ入るためのラッパー。
  # ここで PYTHONPATH を固定してから repo に移動することで、
  # `./build/melchior_main` をどのシェルから起動しても
  # nix 側の Python パッケージを同じ形で参照できるようにする。
  melchiorDev = pkgs.writeShellScriptBin "melchior-dev" ''
    export PYTHONPATH="${melchiorSitePackages}${PYTHONPATH:+:$PYTHONPATH}"
    cd "${melchiorRepo}"
    exec "''${SHELL:-/bin/zsh}" -i
  '';
in
{
  home.packages = [
    melchiorPython
    melchiorDev
  ];

  # repo 配下にいる間だけ Melchior 用の PYTHONPATH を有効にする。
  # 普段のシェル全体を汚さず、`cd ~/Documents/GitHub/melchior` した時だけ
  # 埋め込み Python が必要とする site-packages を見せる。
  programs.zsh.initContent = lib.mkAfter ''
    export MELCHIOR_REPO="${melchiorRepo}"
    export MELCHIOR_PYTHONPATH="${melchiorSitePackages}"

    _update_melchior_pythonpath() {
      case "$PWD/" in
        "$MELCHIOR_REPO"/*|"$MELCHIOR_REPO"/)
          if [[ -z "''${MELCHIOR_OLD_PYTHONPATH+x}" ]]; then
            export MELCHIOR_OLD_PYTHONPATH="$PYTHONPATH"
          fi
          if [[ "$PYTHONPATH" != "$MELCHIOR_PYTHONPATH" ]]; then
            export PYTHONPATH="$MELCHIOR_PYTHONPATH"
          fi
          ;;
        *)
          if [[ -n "''${MELCHIOR_OLD_PYTHONPATH+x}" ]]; then
            if [[ -n "$MELCHIOR_OLD_PYTHONPATH" ]]; then
              export PYTHONPATH="$MELCHIOR_OLD_PYTHONPATH"
            else
              unset PYTHONPATH
            fi
            unset MELCHIOR_OLD_PYTHONPATH
          fi
          ;;
      esac
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd _update_melchior_pythonpath
    _update_melchior_pythonpath
  '';
}
