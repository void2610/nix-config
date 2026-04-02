# Melchior開発用Pythonパッケージ定義
# Melchior の埋め込み Python は build/site-packages や ./site-packages を
# 既定の探索先として読む設計なので、PYTHONPATH を常時ねじ込むより
# Nix で作った env をそのディレクトリへ置く方が単純で壊れにくい。
{ pkgs, lib, ... }:
let
  melchiorRepo = "$HOME/Documents/GitHub/melchior";
  pyquaternionNoTests = pkgs.python312Packages.pyquaternion.overridePythonAttrs (_: {
    doCheck = false;
  });
  # Segment Anything は別プロセスの python3 で動かす。
  # その subprocess から見える python が Homebrew の 3.14 だと、
  # nix で用意した 3.12 向け site-packages と ABI が噛み合わず失敗しやすい。
  # そのため、repo 配下ではコマンド実行用の python も nix の 3.12 に寄せる。
  segmentAnything = pkgs.python312Packages.buildPythonPackage rec {
    pname = "segment-anything";
    version = "1.0";
    format = "setuptools";
    src = pkgs.fetchPypi {
      pname = "segment_anything";
      inherit version;
      hash = "sha256-7Qyfb7B7vvnGI4pwKKE8gnLxumtjBcpz4+BkJmUDc2s=";
    };
    propagatedBuildInputs = with pkgs.python312Packages; [
      torch
      torchvision
    ];
    doCheck = false;
    pythonImportsCheck = [ "segment_anything" ];
  };

  melchiorPythonPackages = ps: with ps; [
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
    torch
    torchvision
  ];

  # SAM 実行専用の追加パッケージ。
  # これらを埋め込み Python の PYTHONPATH に載せると Homebrew 側の OpenCV/FFmpeg と
  # 衝突しやすいため、外部 python subprocess と sam/site-packages だけで使う。
  melchiorSamPackages = ps: with ps; [
    opencv-python
    torch
    torchvision
    segmentAnything
  ];

  # toadflax や関連 addon が実行時 import するパッケージ群。
  # Melchior 本体の build-time dependency ではなく、実行時の埋め込み Python 向け。
  melchiorPython = pkgs.python312.withPackages melchiorPythonPackages;
  melchiorCliPython = pkgs.python312.withPackages (ps:
    (melchiorPythonPackages ps) ++ (melchiorSamPackages ps)
  );
  melchiorCliPythonBin = "${melchiorCliPython}/bin";
  melchiorSamSitePackages = "${melchiorCliPython}/${melchiorCliPython.sitePackages}";
  melchiorEmbeddedSitePackages = "${melchiorPython}/${melchiorPython.sitePackages}";
  melchiorBuildPythonRoot = "${pkgs.python312}";
  melchiorBuildPythonExecutable = "${pkgs.python312}/bin/python3";
  melchiorCmakeWrapper = pkgs.writeShellScriptBin "melchior-cmake" ''
    have_python_exec=0
    have_python_root=0
    extra_args=()
    for arg in "$@"; do
      if [[ "$arg" == -DPython_EXECUTABLE=* ]]; then
        have_python_exec=1
      fi
      if [[ "$arg" == -DPython_ROOT_DIR=* ]]; then
        have_python_root=1
      fi
    done

    if [[ "$have_python_exec" -eq 0 ]]; then
      extra_args+=("-DPython_EXECUTABLE=${melchiorBuildPythonExecutable}")
    fi
    if [[ "$have_python_root" -eq 0 ]]; then
      extra_args+=("-DPython_ROOT_DIR=${melchiorBuildPythonRoot}")
    fi

    exec ${pkgs.cmake}/bin/cmake "''${extra_args[@]}" "$@"
  '';
  melchiorCmakeWrapperBin = "${melchiorCmakeWrapper}/bin";
  melchiorNinjaWrapper = pkgs.writeShellScriptBin "melchior-ninja" ''
    maybe_reconfigure() {
      local current_dir root_dir build_dir cache_file
      current_dir="$(pwd)"
      root_dir=""
      build_dir=""

      if [[ "$current_dir" == "${melchiorRepo}" ]]; then
        root_dir="${melchiorRepo}"
        build_dir="${melchiorRepo}/build"
      elif [[ "$current_dir" == "${melchiorRepo}/build" ]]; then
        root_dir="${melchiorRepo}"
        build_dir="${melchiorRepo}/build"
      else
        return 0
      fi

      cache_file="$build_dir/CMakeCache.txt"
      if [[ ! -f "$cache_file" ]]; then
        return 0
      fi

      if ! grep -q "^Python_EXECUTABLE:UNINITIALIZED=${melchiorBuildPythonExecutable}$" "$cache_file"; then
        echo "Melchior build cache の Python 設定を修復します" >&2
        (
          cd "$build_dir" && \
          ${melchiorCmakeWrapper}/bin/melchior-cmake .. -GNinja \
            -DMELCHIOR_TUTORIALS=OFF \
            -DMELCHIOR_EXAMPLES=ON \
            -DMELCHIOR_BINDING=ON
        )
      fi
    }

    maybe_reconfigure
    exec ${pkgs.ninja}/bin/ninja "$@"
  '';
  melchiorNinjaWrapperBin = "${melchiorNinjaWrapper}/bin";

  # terminal から Melchior 開発環境へ入るためのラッパー。
  # Python パッケージ自体は site-packages の symlink で見せるので、
  # ここでは cmake と SAM 実行用 python3.12 だけ PATH に足す。
  melchiorDev = pkgs.writeShellScriptBin "melchior-dev" ''
    export PATH="${melchiorCmakeWrapperBin}:${melchiorNinjaWrapperBin}:${melchiorCliPythonBin}:$PATH"
    alias cmake=melchior-cmake
    alias ninja=melchior-ninja
    cd "${melchiorRepo}"
    exec "''${SHELL:-/bin/zsh}" -i
  '';
in
{
  home.packages = [
    melchiorDev
  ];

  # Melchior 本体は build/site-packages または ./site-packages を探索する。
  # SAM は runtime/commands/utils/sam/site-packages を探索する。
  # そのため、Nix で作った env をそれぞれのディレクトリへ symlink で配置する。
  home.activation.melchiorSitePackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    build_dir="$HOME/Documents/GitHub/melchior/build"
    repo_site_packages="$HOME/Documents/GitHub/melchior/site-packages"
    build_site_packages="$build_dir/site-packages"
    sam_dir="$HOME/Documents/GitHub/melchior/runtime/commands/utils/sam"
    sam_site_packages="$sam_dir/site-packages"
    git_exclude="$HOME/Documents/GitHub/melchior/.git/info/exclude"

    if [ -d "$HOME/Documents/GitHub/melchior" ]; then
      ln -sfn "${melchiorEmbeddedSitePackages}" "$repo_site_packages"
    fi

    if [ -d "$build_dir" ]; then
      ln -sfn "${melchiorEmbeddedSitePackages}" "$build_site_packages"
    fi

    if [ -d "$sam_dir" ]; then
      if [ -e "$sam_site_packages" ]; then
        chmod -R u+w "$sam_site_packages" 2>/dev/null || true
      fi
      rm -rf "$sam_site_packages"
      mkdir -p "$sam_site_packages"

      for entry in "${melchiorSamSitePackages}"/*; do
        name="$(basename "$entry")"
        if [ "$name" = "cv2" ]; then
          cp -RL "$entry" "$sam_site_packages/"
          chmod -R u+w "$sam_site_packages/$name" 2>/dev/null || true
        else
          ln -sfn "$entry" "$sam_site_packages/$name"
        fi
      done
    fi

    if [ -f "$git_exclude" ] && ! grep -qxF "/site-packages" "$git_exclude"; then
      printf '%s\n' "/site-packages" >> "$git_exclude"
    fi

    if [ -f "$git_exclude" ] && ! grep -qxF "/build/site-packages" "$git_exclude"; then
      printf '%s\n' "/build/site-packages" >> "$git_exclude"
    fi

    if [ -f "$git_exclude" ] && ! grep -qxF "/runtime/commands/utils/sam/site-packages" "$git_exclude"; then
      printf '%s\n' "/runtime/commands/utils/sam/site-packages" >> "$git_exclude"
    fi
  '';

  programs.zsh.initContent = lib.mkAfter ''
    export MELCHIOR_REPO="${melchiorRepo}"
    export MELCHIOR_PYTHON_BIN="${melchiorCliPythonBin}"
    export MELCHIOR_CMAKE_WRAPPER_BIN="${melchiorCmakeWrapperBin}"
    export MELCHIOR_NINJA_WRAPPER_BIN="${melchiorNinjaWrapperBin}"

    _update_melchior_path() {
      case "$PWD/" in
        "$MELCHIOR_REPO"/*|"$MELCHIOR_REPO"/)
          if [[ -z "''${MELCHIOR_OLD_PATH+x}" ]]; then
            export MELCHIOR_OLD_PATH="$PATH"
          fi
          case ":$PATH:" in
            *":$MELCHIOR_CMAKE_WRAPPER_BIN:"*)
              ;;
            *)
              export PATH="$MELCHIOR_CMAKE_WRAPPER_BIN:$MELCHIOR_NINJA_WRAPPER_BIN:$MELCHIOR_PYTHON_BIN:$PATH"
              alias cmake=melchior-cmake
              alias ninja=melchior-ninja
              ;;
          esac
          ;;
        *)
          if [[ -n "''${MELCHIOR_OLD_PATH+x}" ]]; then
            export PATH="$MELCHIOR_OLD_PATH"
            unset MELCHIOR_OLD_PATH
          fi
          unalias cmake 2>/dev/null || true
          unalias ninja 2>/dev/null || true
          ;;
      esac
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd _update_melchior_path
    _update_melchior_path
  '';
}
