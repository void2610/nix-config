# Melchior では、開発 shell に入っていても素の `cmake` / `ninja` だけでは
# 期待した設定が毎回 CMake に渡るとは限らない。
# 例えば Python の実体、Apple 純正 compiler、macOS SDK、GLEW の参照先は
# 一度でも別の値で configure されると build cache に古い値が残りやすい。
#
# そのためここでは、repo 内の `.nix-melchior/bin` に
# - `melchior-cmake`
# - `melchior-ninja`
# の 2 つの wrapper を生成し、
# shell の中で見える `cmake` / `ninja` をそれらへ差し替える。
#
# 方針は「CMake の設定値を shell 変数から毎回補う」ことで、
# ユーザーが毎回長い `-D...` を手で書かなくても
# Melchior 用の前提が崩れにくい状態を作ること。
cat > "$MELCHIOR_REPO/.nix-melchior/bin/melchior-cmake" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# `cmake` の呼び出し引数に、すでに必要な `-D...` が明示されている場合は
# wrapper が上書きしないように、先に有無だけを走査する。
# これにより「通常は安全な既定値を入れるが、必要なら手動 override できる」
# という挙動にしている。
have_python_exec=0
have_python_root=0
have_c_compiler=0
have_cxx_compiler=0
have_linker=0
have_glew_dir=0
have_shared_linker_flags=0
have_module_linker_flags=0
have_exe_linker_flags=0
extra_args=()
for arg in "$@"; do
  if [[ "$arg" == -DPython_EXECUTABLE=* ]]; then
    have_python_exec=1
  fi
  if [[ "$arg" == -DPython_ROOT_DIR=* ]]; then
    have_python_root=1
  fi
  if [[ "$arg" == -DCMAKE_C_COMPILER=* ]]; then
    have_c_compiler=1
  fi
  if [[ "$arg" == -DCMAKE_CXX_COMPILER=* ]]; then
    have_cxx_compiler=1
  fi
  if [[ "$arg" == -DCMAKE_LINKER=* ]]; then
    have_linker=1
  fi
  if [[ "$arg" == -DGLEW_DIR=* ]]; then
    have_glew_dir=1
  fi
  if [[ "$arg" == -DCMAKE_SHARED_LINKER_FLAGS=* ]]; then
    have_shared_linker_flags=1
  fi
  if [[ "$arg" == -DCMAKE_MODULE_LINKER_FLAGS=* ]]; then
    have_module_linker_flags=1
  fi
  if [[ "$arg" == -DCMAKE_EXE_LINKER_FLAGS=* ]]; then
    have_exe_linker_flags=1
  fi
done

# ここで補っているのは、Melchior の configure が壊れやすい項目だけ。
# とくに Python と compiler / linker は build cache に残ると復旧が面倒なので、
# 未指定時は毎回 shell で固定した値を差し込む。
if [[ "$have_python_exec" -eq 0 ]]; then
  extra_args+=("-DPython_EXECUTABLE=$MELCHIOR_BUILD_PYTHON_EXECUTABLE")
fi
if [[ "$have_python_root" -eq 0 ]]; then
  extra_args+=("-DPython_ROOT_DIR=$MELCHIOR_BUILD_PYTHON_ROOT")
fi
if [[ "$have_c_compiler" -eq 0 ]]; then
  extra_args+=("-DCMAKE_C_COMPILER=$MELCHIOR_NATIVE_CLANG")
fi
if [[ "$have_cxx_compiler" -eq 0 ]]; then
  extra_args+=("-DCMAKE_CXX_COMPILER=$MELCHIOR_NATIVE_CLANGXX")
fi
if [[ "$have_linker" -eq 0 ]]; then
  extra_args+=("-DCMAKE_LINKER=$MELCHIOR_NATIVE_LD")
fi
if [[ "$have_glew_dir" -eq 0 ]]; then
  extra_args+=("-DGLEW_DIR=$MELCHIOR_GLEW_DIR")
fi
if [[ "$have_shared_linker_flags" -eq 0 ]]; then
  extra_args+=("-DCMAKE_SHARED_LINKER_FLAGS=$MELCHIOR_EXTRA_LINK_FLAGS")
fi
if [[ "$have_module_linker_flags" -eq 0 ]]; then
  extra_args+=("-DCMAKE_MODULE_LINKER_FLAGS=$MELCHIOR_EXTRA_LINK_FLAGS")
fi
if [[ "$have_exe_linker_flags" -eq 0 ]]; then
  extra_args+=("-DCMAKE_EXE_LINKER_FLAGS=$MELCHIOR_EXTRA_LINK_FLAGS")
fi
if [[ -n "${SDKROOT:-}" ]]; then
  extra_args+=("-DCMAKE_OSX_SYSROOT=$SDKROOT")
fi
if [[ -n "${MACOSX_DEPLOYMENT_TARGET:-}" ]]; then
  extra_args+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET")
fi

# 実際の CMake 本体は Nix の `cmake` を使う。
# wrapper 自体は前処理だけを担当し、最後は本物へそのまま委譲する。
exec "@cmakeBin@" "${extra_args[@]}" "$@"
EOF
chmod +x "$MELCHIOR_REPO/.nix-melchior/bin/melchior-cmake"
ln -sfn "$MELCHIOR_REPO/.nix-melchior/bin/melchior-cmake" "$MELCHIOR_REPO/.nix-melchior/bin/cmake"

cat > "$MELCHIOR_REPO/.nix-melchior/bin/melchior-ninja" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# `ninja` 自体は薄い wrapper に留める。
# 役割は「いま build cache に残っている Python 設定が正しいか」を見ることだけ。
# ここで毎回 configure を強制すると、FetchContent や外部依存まで巻き込んで
# build が不安定になるので、必要なときだけ最小限の修復を入れる。
maybe_reconfigure() {
  local current_dir build_dir root_dir cache_file
  current_dir="$(pwd)"
  build_dir=""
  root_dir=""

  if [[ -f "$current_dir/CMakeCache.txt" && -f "$current_dir/../CMakeLists.txt" ]]; then
    build_dir="$current_dir"
    root_dir="$(cd "$current_dir/.." && pwd)"
  elif [[ -f "$current_dir/CMakeLists.txt" && -d "$current_dir/build" ]]; then
    build_dir="$current_dir/build"
    root_dir="$current_dir"
  else
    return 0
  fi

  cache_file="$build_dir/CMakeCache.txt"
  if [[ ! -f "$cache_file" ]]; then
    return 0
  fi

  # もっとも壊れやすかったのが Python のずれなので、
  # まずは `Python_EXECUTABLE` だけを監視対象にする。
  # ここが Nix shell の Python から外れていたら、binding 周りの configure が
  # 失敗しやすいため、その場で `cmake ..` を一度だけ流し直す。
  if ! grep -Eq "^Python_EXECUTABLE(:FILEPATH|:UNINITIALIZED)=$MELCHIOR_BUILD_PYTHON_EXECUTABLE$" "$cache_file"; then
    echo "Melchior build cache の Python 設定を修復します" >&2
    (
      cd "$build_dir"
      "$root_dir/.nix-melchior/bin/melchior-cmake" .. -GNinja \
        -DMELCHIOR_TUTORIALS=OFF \
        -DMELCHIOR_EXAMPLES=ON \
        -DMELCHIOR_BINDING=ON
    )
  fi
}

maybe_reconfigure
# 実際のビルド本体は素の `ninja` に任せる。
exec "@ninjaBin@" "$@"
EOF
chmod +x "$MELCHIOR_REPO/.nix-melchior/bin/melchior-ninja"
ln -sfn "$MELCHIOR_REPO/.nix-melchior/bin/melchior-ninja" "$MELCHIOR_REPO/.nix-melchior/bin/ninja"
