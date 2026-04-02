# nix-config

Nix + nix-darwin + home-manager による macOS 設定管理リポジトリ。
複数ホストをプロファイルで管理する構造にしている。

## ホスト構成

| flake target | ホスト名 | profile | 用途 |
|---|---|---|---|
| `.#Macintosh` | Macintosh | game | メイン機（趣味・ゲーム） |
| `.#game-dev` | game-dev | game | ゲーム開発機 |
| `.#PCmac24055` | PCmac24055 | work | 会社開発機（Melchior 開発） |
| `.#server-node` | server-node | server | サーバーノード（LLM agent・自動化） |

## ディレクトリ構成

```
nix-config/
├── flake.nix              # 全ホストの定義・入口
├── flake.lock
├── .sops.yaml             # sops-nix 暗号化設定
├── BOOTSTRAP.md           # 新しい Mac へのセットアップ手順
├── secrets/               # sops-nix で暗号化した SSH 鍵等
├── pkgs/                  # カスタム Nix パッケージ定義
├── nix-darwin/            # macOS システム設定層 → nix-darwin/README.md
└── home-manager/          # ユーザー環境設定層 → home-manager/README.md
```

## 使用ツール

| ツール | 用途 |
|---|---|
| [nix-darwin](https://github.com/LnL7/nix-darwin) | macOS のシステム設定を宣言的に管理 |
| [home-manager](https://github.com/nix-community/home-manager) | ユーザー環境（パッケージ・dotfiles）を管理 |
| [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) | Homebrew パッケージを Nix で宣言的に管理 |
| [sops-nix](https://github.com/Mic92/sops-nix) | 暗号化した secrets を Nix から配置 |

## 設計方針

- **ホスト (hosts/)**: ホスト名・ユーザー名・ホームディレクトリなどの固有値のみ
- **プロファイル (profiles/)**: 用途別の差分（インストールするアプリ等）
- **モジュール (modules/)**: 全プロファイル共通の設定
- **プロジェクト別モジュール**: プロジェクト固有の依存は専用サブディレクトリで管理（例: `melchior/`）
- システム設定は nix-darwin、ユーザー設定は home-manager で明確に分離
- 単なる dotfiles は別リポジトリで管理

## 日常的な使い方

```bash
# 設定変更を反映
cd ~/nix-config
darwin-rebuild switch --flake .#PCmac24055

# パッケージのバージョン更新
nix flake update
darwin-rebuild switch --flake .#PCmac24055

# ロールバック
darwin-rebuild --rollback
```

## 新しいホストを追加するとき

1. `nix-darwin/hosts/` に `<host-name>.nix` を作成
2. `flake.nix` の `darwinConfigurations` に target を追加
3. 必要に応じて `home-manager/profiles/` に差分を追加
4. 共通化できる差分は `modules/` に切り出す

## 動作環境

- macOS 15 (Sequoia)
- Apple Silicon (aarch64-darwin)
