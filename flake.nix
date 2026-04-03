{
  description = "shuya の Mac 設定";

  inputs = {
    # nixpkgs（unstable）
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # nix-darwin: macOS システム設定管理
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager: ユーザー環境管理
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-homebrew: Homebrew の宣言的管理
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # sops-nix: 暗号化した secrets の配置
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, sops-nix }:
  let
    system = "aarch64-darwin";
    melchiorRepo = "/Users/shuya.izumi/Documents/GitHub/melchior";

    # Melchior は共有 repo なので、flake.nix / flake.lock を repo に置かず、
    # 自分の nix-config 側だけで開発環境を管理する。
    #
    # ここで定義する `melchior` dev shell に入ると、以前 repo 内の flake でやっていた
    # 次の準備を同じように自動化する。
    # - Python 3.12 の固定
    # - CMake / Ninja wrapper の生成
    # - build/site-packages と sam/site-packages の配置
    # - Apple 純正 toolchain を使った configure / build
    #
    # 使い方は `nix develop ~/nix-config#melchior`。
    melchiorDevShell =
      let
        pkgs = import nixpkgs { inherit system; };
        # この環境では Homebrew 側のライブラリが新しい macOS SDK で組まれており、
        # Nix の clang wrapper が持つ SDK と混ざるとリンクで壊れやすい。
        # そのため、Melchior のコンパイルとリンクは Command Line Tools の
        # ネイティブ clang / ld / SDK に寄せている。
        nativeSdkRoot = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk";
        nativeDeploymentTarget = "26.0";

        # pyquaternion は upstream のテストが現在の NumPy と噛み合わず、
        # 開発環境を作るだけで失敗することがあったためテストを外して使う。
        pyquaternionNoTests = pkgs.python312Packages.pyquaternion.overridePythonAttrs (_: {
          doCheck = false;
        });

        # Segment Anything は nixpkgs に無いので PyPI から取得して Python package 化する。
        # これで SAM 用 runner から `import segment_anything` がそのまま通る。
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

        # Melchior 本体の埋め込み Python が見る package 群。
        # ここには OpenCV を入れず、埋め込み Python 側でのネイティブ衝突を避ける。
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
          pyquaternionNoTests
        ];

        # SAM 実行用の別プロセス Python で使う package 群。
        # こちらには OpenCV を含める。
        melchiorSamPackages = ps: with ps; [
          opencv-python
          torch
          torchvision
          segmentAnything
        ];

        # Melchior 本体用 Python と、CLI / SAM 実行用 Python を分ける。
        # 前者は埋め込み Python 向け site-packages の実体、
        # 後者は `python3` や SAM ランナーが使う実行環境になる。
        melchiorPython = pkgs.python312.withPackages melchiorPythonPackages;
        melchiorCliPython = pkgs.python312.withPackages (ps:
          (melchiorPythonPackages ps) ++ (melchiorSamPackages ps)
        );
        melchiorEmbeddedSitePackages = "${melchiorPython}/${melchiorPython.sitePackages}";
        melchiorSamSitePackages = "${melchiorCliPython}/${melchiorCliPython.sitePackages}";
      in
      pkgs.mkShell {
        packages = [
          pkgs.assimp
          pkgs.cmake
          pkgs.git
          pkgs.glew
          pkgs.glfw
          pkgs.glm
          pkgs.jsoncpp
          pkgs.ninja
          pkgs.pkg-config
          pkgs.zstd
          melchiorCliPython
        ];

        shellHook = ''
          # shellHook は dev shell に入るたびに実行される。
          # ここで repo 内に wrapper や site-packages を整え、手作業をなくす。
          export MELCHIOR_REPO="${melchiorRepo}"
          if [[ "$PWD" != "$MELCHIOR_REPO"* ]]; then
            cd "$MELCHIOR_REPO"
          fi

          # CMake の FindPython が 3.9 などを拾うと binding configure が壊れる。
          # そのため、ビルドに使う Python 3.12 を明示で固定する。
          export MELCHIOR_BUILD_PYTHON_ROOT="${pkgs.python312}"
          export MELCHIOR_BUILD_PYTHON_EXECUTABLE="${pkgs.python312}/bin/python3"
          export MELCHIOR_EMBEDDED_SITE_PACKAGES="${melchiorEmbeddedSitePackages}"
          export MELCHIOR_SAM_SITE_PACKAGES_SRC="${melchiorSamSitePackages}"
          export MELCHIOR_CMAKE_BIN="${pkgs.cmake}/bin/cmake"

          # macOS の純正 compiler / linker を使う。
          # これをしないと Nix 側の wrapper と Homebrew 側ライブラリの SDK が混ざり、
          # `Unsupported stack probing method` のようなリンクエラーが出やすい。
          export MELCHIOR_NATIVE_CLANG="/Library/Developer/CommandLineTools/usr/bin/clang"
          export MELCHIOR_NATIVE_CLANGXX="/Library/Developer/CommandLineTools/usr/bin/clang++"
          export MELCHIOR_NATIVE_LD="/Library/Developer/CommandLineTools/usr/bin/ld"
          export CC="$MELCHIOR_NATIVE_CLANG"
          export CXX="$MELCHIOR_NATIVE_CLANGXX"
          export LD="$MELCHIOR_NATIVE_LD"
          export SDKROOT="${nativeSdkRoot}"
          export MACOSX_DEPLOYMENT_TARGET="${nativeDeploymentTarget}"

          # 一部ライブラリは include path の伝播が弱く、そのままだと
          # `glm/glm.hpp` や `GLFW/glfw3.h` を見つけられない箇所がある。
          # そのため開発 shell 側で補助的に include path を足す。
          export CPATH="${pkgs.glfw}/include:${pkgs.glew.dev}/include:${pkgs.glm}/include''${CPATH:+:$CPATH}"

          # repo 側へ寄せた依存を CMake / pkg-config が優先して見つけるようにする。
          export CMAKE_PREFIX_PATH="${pkgs.assimp}:${pkgs.glfw}:${pkgs.glew}:${pkgs.glm}:${pkgs.jsoncpp}:${pkgs.zstd}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
          export PKG_CONFIG_PATH="${pkgs.glfw}/lib/pkgconfig:${pkgs.glew}/lib/pkgconfig:${pkgs.jsoncpp.dev}/lib/pkgconfig:${pkgs.zstd.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

          mkdir -p "$MELCHIOR_REPO/.nix-melchior/bin"

          # `cmake` wrapper:
          # 普通に `cmake ..` と打っても、Python 3.12 / 純正 clang / 純正 ld /
          # ネイティブ SDK が毎回自動で入るようにする。
          # 実行環境に依存して別の Python や toolchain を拾うのを防ぐためのもの。
          cat > "$MELCHIOR_REPO/.nix-melchior/bin/melchior-cmake" <<'EOF'
          #!/usr/bin/env bash
          set -euo pipefail
          have_python_exec=0
          have_python_root=0
          have_c_compiler=0
          have_cxx_compiler=0
          have_linker=0
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
          done

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
          if [[ -n "''${SDKROOT:-}" ]]; then
            extra_args+=("-DCMAKE_OSX_SYSROOT=$SDKROOT")
          fi
          if [[ -n "''${MACOSX_DEPLOYMENT_TARGET:-}" ]]; then
            extra_args+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET")
          fi

          exec "$MELCHIOR_CMAKE_BIN" "''${extra_args[@]}" "$@"
          EOF
          chmod +x "$MELCHIOR_REPO/.nix-melchior/bin/melchior-cmake"
          ln -sfn "$MELCHIOR_REPO/.nix-melchior/bin/melchior-cmake" "$MELCHIOR_REPO/.nix-melchior/bin/cmake"

          # `ninja` wrapper:
          # 既存 build cache が古い Python を指していた場合だけ自動で再 configure してから
          # 本来の ninja を呼ぶ。これで毎回 `cmake ..` を手で打たずに済む。
          cat > "$MELCHIOR_REPO/.nix-melchior/bin/melchior-ninja" <<'EOF'
          #!/usr/bin/env bash
          set -euo pipefail

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
          exec ${pkgs.ninja}/bin/ninja "$@"
          EOF
          chmod +x "$MELCHIOR_REPO/.nix-melchior/bin/melchior-ninja"
          ln -sfn "$MELCHIOR_REPO/.nix-melchior/bin/melchior-ninja" "$MELCHIOR_REPO/.nix-melchior/bin/ninja"

          # SAM 用ディレクトリは先に用意しておく。
          mkdir -p "$MELCHIOR_REPO/runtime/commands/utils/sam"

          # Melchior の埋め込み Python が最初から見る `site-packages` を repo 内に配置する。
          # ここは Nix store 上の Python env を symlink で見せるだけにしている。
          ln -sfn "$MELCHIOR_EMBEDDED_SITE_PACKAGES" "$MELCHIOR_REPO/site-packages"

          # 一部起動経路では build 側の `site-packages` が参照されるため、
          # repo 直下だけでなく build ディレクトリ側にも同じものを置く。
          if [[ -d "$MELCHIOR_REPO/build" ]]; then
            ln -sfn "$MELCHIOR_EMBEDDED_SITE_PACKAGES" "$MELCHIOR_REPO/build/site-packages"
          fi

          # SAM 用 `site-packages` は毎回作り直す。
          # 以前の結果が残っていると cv2 のロードや権限で壊れやすいため。
          if [[ -e "$MELCHIOR_REPO/runtime/commands/utils/sam/site-packages" ]]; then
            chmod -R u+w "$MELCHIOR_REPO/runtime/commands/utils/sam/site-packages" 2>/dev/null || true
            rm -rf "$MELCHIOR_REPO/runtime/commands/utils/sam/site-packages"
          fi

          mkdir -p "$MELCHIOR_REPO/runtime/commands/utils/sam/site-packages"
          for entry in "$MELCHIOR_SAM_SITE_PACKAGES_SRC"/*; do
            name="$(basename "$entry")"
            if [[ "$name" == "cv2" ]]; then
              # cv2 は symlink のままだと再帰 import 判定に引っかかることがある。
              # そのため、ここだけは実体コピーにしている。
              cp -RLf "$entry" "$MELCHIOR_REPO/runtime/commands/utils/sam/site-packages/"
              chmod -R u+w "$MELCHIOR_REPO/runtime/commands/utils/sam/site-packages/$name" 2>/dev/null || true
            else
              # torch や segment_anything などは symlink で十分。
              ln -sfn "$entry" "$MELCHIOR_REPO/runtime/commands/utils/sam/site-packages/$name"
            fi
          done

          # 生成される補助ディレクトリを git status に出さない。
          mkdir -p "$MELCHIOR_REPO/.git/info"
          touch "$MELCHIOR_REPO/.git/info/exclude"
          grep -qxF "/site-packages" "$MELCHIOR_REPO/.git/info/exclude" || printf '%s\n' "/site-packages" >> "$MELCHIOR_REPO/.git/info/exclude"
          grep -qxF "/build/site-packages" "$MELCHIOR_REPO/.git/info/exclude" || printf '%s\n' "/build/site-packages" >> "$MELCHIOR_REPO/.git/info/exclude"
          grep -qxF "/runtime/commands/utils/sam/site-packages" "$MELCHIOR_REPO/.git/info/exclude" || printf '%s\n' "/runtime/commands/utils/sam/site-packages" >> "$MELCHIOR_REPO/.git/info/exclude"
          grep -qxF "/.nix-melchior" "$MELCHIOR_REPO/.git/info/exclude" || printf '%s\n' "/.nix-melchior" >> "$MELCHIOR_REPO/.git/info/exclude"

          # 以後の `cmake` / `ninja` は wrapper が優先される。
          export PATH="$MELCHIOR_REPO/.nix-melchior/bin:$PATH"

          # shell に入った直後に、何が選ばれたかを見えるようにしておく。
          echo "Melchior Nix shell ready"
          echo "  python: $MELCHIOR_BUILD_PYTHON_EXECUTABLE"
          echo "  cmake : $MELCHIOR_REPO/.nix-melchior/bin/cmake"
          echo "  ninja : $MELCHIOR_REPO/.nix-melchior/bin/ninja"
        '';
      };

    mkDarwinConfiguration =
      {
        configName,
        profile,
      }:
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit profile; };
        modules = [
          (import ./nix-darwin/hosts/default.nix { inherit configName; })

          nix-homebrew.darwinModules.nix-homebrew
          ({ config, ... }: {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = config.system.primaryUser;
              autoMigrate = true;
            };
          })

          sops-nix.darwinModules.sops

          home-manager.darwinModules.home-manager
          ({ config, ... }:
            let
              username = config.system.primaryUser;
              homeDirectory = config.users.users.${username}.home;
            in
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit profile;
                  inherit homeDirectory username;
                };
                users.${username} = {
                  imports = [
                    ./home-manager/users/default.nix
                    (./home-manager/profiles + "/${profile}.nix")
                  ];
                };
              };
            })
        ];
      };
  in
  {
    devShells.${system}.melchior = melchiorDevShell;

    darwinConfigurations = {
      Macintosh = mkDarwinConfiguration {
        configName = "Macintosh";
        profile = "game";
      };

      "game-dev" = mkDarwinConfiguration {
        configName = "game-dev";
        profile = "game";
      };

      "PCmac24055" = mkDarwinConfiguration {
        configName = "work-dev";
        profile = "work";
      };

      "server-node" = mkDarwinConfiguration {
        configName = "server-node";
        profile = "server";
      };
    };
  };
}
