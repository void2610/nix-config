# .nix-config

Nix を使った macOS 設定管理リポジトリです。
共通モジュールを積み上げて、`game` / `work` / `server` の複数ホストを分けて運用できる構造にしています。

## ディレクトリ構成

```text
.nix-config/
├── flake.nix
├── home-manager/
│   ├── modules/
│   │   ├── git.nix
│   │   ├── packages.nix
│   │   ├── shell.nix
│   │   └── tmux.nix
│   ├── profiles/
│   │   ├── game.nix
│   │   ├── server.nix
│   │   └── work.nix
│   └── users/
│       └── shuya.nix
└── nix-darwin/
    ├── hosts/
    │   ├── Macintosh.nix
    │   ├── game-dev.nix
    │   ├── server-node.nix
    │   └── work-dev.nix
    └── modules/
        ├── base.nix
        ├── defaults.nix
        ├── homebrew.nix
        ├── nix-core.nix
        ├── secrets.nix
        └── security.nix
```

## 方針

- インストールや有効化に関わるものは `nix-config` で管理する
- 単なる設定ファイルは基本的に `dotfiles` 側で管理する
- Homebrew は `nix-homebrew` 経由で宣言的に管理する
- ホスト固有情報は `hosts/` に置き、用途差分は `profiles/` に置く

## ホスト構成

| flake target | profile | 想定用途 |
|---|---|---|
| `.#Macintosh` | `game` | 現在のメイン機 |
| `.#game-dev` | `game` | ゲーム開発メイン機 |
| `.#work-dev` | `work` | 会社用開発機 |
| `.#server-node` | `server` | 常時稼働のサブ機。LLM agent と自動化実行用 |

`hosts/` はホスト名、primary user、ホームディレクトリのような固有値だけを持ちます。インストールアプリや shell の差分は `profile` で切り替えます。

## profile ごとの差分

- `game`: Unity / Rider / Steam / OBS など、制作と趣味の GUI を含む
- `work`: 開発系 GUI を中心にし、ゲーム用途のアプリは外す
- `server`: 常時稼働向け。LLM agent、Unity 開発、ブラウザ自動化に必要な GUI とランタイムを残す

## 使用ツール

| ツール | 用途 |
|---|---|
| [nix-darwin](https://github.com/LnL7/nix-darwin) | macOS のシステム設定を宣言的に管理 |
| [home-manager](https://github.com/nix-community/home-manager) | ユーザー環境（パッケージ・dotfiles）を管理 |
| [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) | Homebrew パッケージを Nix で宣言的に管理 |
| [sops-nix](https://github.com/Mic92/sops-nix) | 暗号化した secrets を Nix から配置 |

## セットアップ（新しいMacへの移行）

### 1. Nixのインストール

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

ターミナルを再起動してから確認:

```bash
nix --version
```

### 2. リポジトリのクローン

```bash
git clone https://github.com/void2610/.nix-config.git ~/.nix-config
git clone https://github.com/void2610/dotfiles.git ~/dotfiles
```

### 3. ホスト名の確認

```bash
scutil --get LocalHostName
```

新しい Mac を追加するときは `nix-darwin/hosts/` に host file を追加し、`flake.nix` の `darwinConfigurations` に target を足します。

### 4. nix-darwinの初回インストール

```bash
cd ~/.nix-config
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#work-dev
```

### 5. secretsの準備

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

表示された公開鍵を `.sops.yaml` に入れてから、`secrets/common.yaml` を `sops -e -i` で暗号化します。

### 6. dotfilesのリンク

```bash
cd ~/dotfiles
./install.sh
```

### 7. 手動インストールアプリの確認

宣言化できないアプリは `~/dotfiles/MANUAL_APPS.md` を見て個別に復元します。

## 日常的な使い方

### 設定変更の反映

```bash
cd ~/.nix-config
sudo darwin-rebuild switch --flake .#work-dev
```

別ホストでは target 名を切り替えます。例:

```bash
sudo darwin-rebuild switch --flake .#work-dev
```

### パッケージ・ツールのバージョン更新

```bash
cd ~/.nix-config
nix flake update
sudo darwin-rebuild switch --flake .#work-dev
```

### ロールバック

```bash
sudo darwin-rebuild --rollback
```

## 動作環境

- macOS 15 (Sequoia)
- Apple Silicon (aarch64-darwin)

## 再現できるもの

- Homebrew formula / cask / MAS アプリ
- macOS システム設定
- `home-manager` で有効化している CLI / shell 環境
- `dotfiles` に置いている各種設定ファイル
- `sops-nix` で復元する secrets
- Node.js 22 系の基準実行環境

## 手動で戻すもの

- `dotfiles/MANUAL_APPS.md` にあるアプリ
- Unity Editor 本体と Hub 内モジュール
- アプリのログイン状態、ライセンス、同期データ

## 手動復元メモ

- Unity Hub は宣言されていますが、Unity Editor は手動で入れます。
- 現在使っている Unity Editor は `6000.3.10f1` (`Unity 6.3 LTS`) です。
- 現在選択している Unity モジュールは `Mac Build Support (IL2CPP)`, `Web Build Support`, `Windows Build Support (Mono)`, `日本語` です。

## 追加するとき

1. `nix-darwin/hosts/` に新しい host file を作る
2. `flake.nix` の `darwinConfigurations` に target を足す
3. 必要なら `home-manager/profiles/` と `nix-darwin/modules/homebrew.nix` に差分を追加する
4. 共通化できる差分は `modules/` 側へ戻す
