# nix-config

Nix + nix-darwin + home-manager による macOS 設定管理リポジトリ。
複数ホストをプロファイルで管理する構造にしている。

## 構成

| 層 | ディレクトリ | 役割 |
|---|---|---|
| システム | `nix-darwin/` | macOS システム設定・Homebrew |
| ユーザー | `home-manager/` | CLI パッケージ・シェル・dotfiles |
| 共通 | `pkgs/` | nixpkgs にないカスタムパッケージ |
| 秘密情報 | `secrets/` | sops-nix で暗号化した SSH 鍵等 |

## ホスト

| flake target | profile | 用途 |
|---|---|---|
| `.#game` | game | メイン機（趣味・ゲーム） |
| `.#work` | work | 会社開発機 |
| `.#server` | server | サーバーノード |

## 設計方針

- **ホスト**: 固有値（ホスト名・ユーザー名）のみ
- **プロファイル**: 用途別の差分
- **モジュール**: 全プロファイル共通の設定
- プロジェクト固有の依存は専用サブディレクトリで管理（例: `melchior/`）
- システム設定と ユーザー設定を nix-darwin / home-manager で明確に分離

## 日常操作

```bash
darwin-rebuild switch --flake .#work   # 設定反映
nix flake update && darwin-rebuild switch …  # パッケージ更新
darwin-rebuild --rollback                    # ロールバック
```

セットアップ手順は `BOOTSTRAP.md` を参照。
