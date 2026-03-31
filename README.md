# .nix-config

Nix を使った macOS 設定管理リポジトリです。
共通モジュールを積み上げて、今後 `game` / `work` / `server` のような複数ホストへ広げやすい構造にしています。

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
│   └── users/
│       └── shuya.nix
└── nix-darwin/
    ├── hosts/
    │   └── Macintosh.nix
    └── modules/
        ├── defaults.nix
        ├── homebrew.nix
        ├── nix-core.nix
        └── security.nix
```

## 方針

- インストールや有効化に関わるものは `nix-config` で管理する
- 単なる設定ファイルは基本的に `dotfiles` 側で管理する
- Homebrew は `nix-homebrew` 経由で宣言的に管理する
- `hosts/` と `users/` を増やして複数 Mac へ展開する

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

ホストごとのエントリは `nix-darwin/hosts/` に置きます。新しい Mac を追加するときは、既存ホストをベースに新しい host module を作ります。

### 4. nix-darwinの初回インストール

```bash
cd ~/.nix-config
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#Macintosh
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
sudo darwin-rebuild switch --flake .#Macintosh
```

### パッケージ・ツールのバージョン更新

```bash
cd ~/.nix-config
nix flake update
sudo darwin-rebuild switch --flake .#Macintosh
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

## 今後の拡張

- `nix-darwin/hosts/` に `game`, `work`, `server` 用ホストを追加
- `home-manager/users/` にユーザー別エントリを追加
- 共通化したい設定は `modules/` に寄せる
