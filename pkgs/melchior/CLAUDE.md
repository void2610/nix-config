# Melchior Nix Notes

このディレクトリの目的は、共有 repo `~/Documents/GitHub/melchior` に
個人用の Nix 設定を持ち込まずに、自分用の開発 shell を提供すること。

## 前提

- Melchior 本体は共有リポジトリなので、repo 側へ `flake.nix` を commit しない
- 個人用設定は `~/nix-config` に置く
- 外側の入口は `mel`
- shell 内の build / run は `b`

## 守るべき方針

- `b` はただの薄い shell 関数に保つ
- wrapper に build orchestration を詰め込みすぎない
- `melchior-ninja` は最小限の cache 修復だけに留める
- Python 環境は「埋め込み Python 用」と「SAM 用」を分けたままにする
- `opencv-python` を埋め込み Python 側へ戻さない

## 理由

- `opencv-python` を埋め込み Python 側に入れると、macOS で native library 衝突が起きやすい
- 毎回 reconfigure する wrapper は MuJoCo / FetchContent 系の地雷を踏みやすい
- repo 側へ個人用 Nix 設定を置くと、共有運用と衝突する

## 変更時の見どころ

- package 構成:
  - `dev-shell.nix`
- 環境変数:
  - `env.sh`
- GLEW 補正:
  - `glew.sh`
- `cmake` / `ninja` wrapper:
  - `wrappers.sh`
- `site-packages` 配置:
  - `site-packages.sh`
- shell 関数:
  - `shell-functions.sh`

## 変更しない方がよいもの

- `b` を複雑な自動修復コマンドにしない
- shell に入るたびに大規模 reconfigure を走らせない
- Melchior repo 側へ個人用 symlink や flake を戻さない
