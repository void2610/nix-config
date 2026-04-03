# Melchior Nix Dev Shell

このディレクトリは、`~/Documents/GitHub/melchior` 用の個人開発環境を
`~/nix-config` 側で管理するための設定です。

共有リポジトリである Melchior 本体には `flake.nix` を置かず、
自分だけが `nix develop ~/nix-config#melchior` で入れる形にしています。

## 何をしているか

この dev shell は、Melchior を macOS 上でビルドして起動するために
最低限必要なものをまとめて用意します。

- CMake / Ninja / Python 3.12 を揃える
- Melchior が使う C++ ライブラリを Nix から見えるようにする
- Melchior 本体の埋め込み Python が読む `site-packages` を repo 内に配置する
- SAM 実行用の別 Python 環境も repo 内に配置する
- `cmake` / `ninja` を wrapper 化して、壊れやすい configure 条件を毎回補う
- shell の中で `b` を実行すると `ninja melchior_main toadflax -j8 && ./melchior_main` が動くようにする

## 使い方

外側の通常 shell からは `mel` を使います。

```bash
mel
```

これは中で `nix develop ~/nix-config#melchior` を実行します。

Melchior 用 shell に入った後は `b` でビルドと起動を行います。

```bash
b
```

`b` の中身は単純で、`~/Documents/GitHub/melchior/build` に移動して
`ninja melchior_main toadflax -j8 && ./melchior_main` を呼ぶだけです。

## ファイルの役割

- `dev-shell.nix`
  - Melchior 用 dev shell の本体です
  - 必要な Nix package を並べ、shellHook で読む補助スクリプトを組み立てます
- `env.sh`
  - shell に入った直後の環境変数を作ります
  - `SDKROOT`, `CMAKE_PREFIX_PATH`, `PKG_CONFIG_PATH` などをここで定義します
- `glew.sh`
  - macOS でそのままだと壊れる `glew-config.cmake` の見え方を補正します
- `wrappers.sh`
  - `cmake` と `ninja` の wrapper を repo 内 `.nix-melchior/bin` に生成します
- `site-packages.sh`
  - Melchior 本体用 / SAM 用の `site-packages` を repo 内へ配置します
- `shell-functions.sh`
  - shell 内で使う `b` 関数を定義します
- `shell-hook.sh`
  - 上の小さいスクリプトを読む入口です

## なぜこんな構成か

### 1. 共有 repo に個人用 Nix 設定を置きたくない

Melchior は共有リポジトリです。
ここに個人用 `flake.nix` を commit すると、他の開発者にまで
「この repo は Nix 前提らしい」という誤解を与えやすくなります。

そのため、Nix の設定は `~/nix-config` に置き、
Melchior 側は通常の repo のままにしています。

### 2. Homebrew / Nix / macOS SDK が混ざると壊れやすい

Melchior は依存が多く、何も考えずに `cmake` を実行すると、
次のような不整合が起きやすいです。

- Python が前回の configure 時のものを掴んだまま残る
- compiler / linker が Nix 側と Apple 純正でずれる
- GLEW や PCL が別の経路で見つかり、configure は通っても link で壊れる

このため wrapper で「壊れやすい値だけ」を毎回差し込みます。

### 3. 埋め込み Python と SAM 用 Python を分けたい

Melchior 本体は埋め込み Python を持っています。
一方で `CmdSamPcd` は別プロセスの Python で動きます。

この 2 つで同じ Python package 構成を使うと、`cv2` や OpenGL 系 native module が
衝突しやすくなります。

そのため、ここでは Python 環境を 2 つに分けています。

- Melchior 本体用
  - `numpy`, `scipy`, `torch` など
  - `opencv-python` は入れない
- SAM 用
  - 上記に加えて `opencv-python`, `segment-anything`

## 制約

### OpenCV は埋め込み Python 側に入れない

`opencv-python` を Melchior 本体の埋め込み Python 側に直接見せると、
OpenGL / GLFW / ffmpeg 系の native library が二重に読み込まれやすく、
macOS で warning やクラッシュの原因になります。

そのため OpenCV は SAM 用の別 Python にだけ入れています。

### wrapper は最低限の修復だけをする

`melchior-ninja` は毎回フル configure をするのではなく、
`Python_EXECUTABLE` が明らかにずれているときだけ補正します。

毎回大きく reconfigure すると、MuJoCo の `FetchContent` や外部 patch まで
巻き込んで逆に build が不安定になるためです。

### `build` ディレクトリは既存の作法に合わせる

この設定は `build` を前提にしています。
`build-debug` のような別ディレクトリを増やす運用は、今の wrapper や `b` とは
相性がよくありません。

## 困ったとき

### shell に入り直したい

一度抜けて、外側からもう一度 `mel` を実行してください。

### build cache が壊れた

まず shell の中で `cmake` を直接細かくいじらず、`b` で再試行してください。
それでも壊れている場合だけ `build/CMakeCache.txt` や `build/_deps` を疑います。

### `site-packages` 周りの問題が起きた

`site-packages.sh` は毎回 repo 内の配置を作り直します。
壊れている場合は shell を入り直すと復旧することが多いです。

## 今後やるなら

- `b` 以外の補助関数を増やすなら `shell-functions.sh` に追加する
- configure 既定値を変えるなら `wrappers.sh` を直す
- Python package 構成を変えるなら `dev-shell.nix` の
  `melchiorPythonPackages` / `melchiorSamPackages` を直す

まずは「Melchior 用の前提を shell へ閉じ込める」ことを優先し、
repo 本体には個人用 Nix 設定を持ち込まない方針を維持すること。
