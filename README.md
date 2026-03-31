# .nix-config

Nixを使ったMacの設定管理リポジトリ。

## 構成

```
.nix-config/
├── flake.nix                 # nixpkgs / nix-darwin / home-manager / nix-homebrew の統合
├── home-manager/
│   └── home.nix              # ユーザー環境（パッケージ等）
└── nix-darwin/
    ├── configuration.nix     # macOS システム設定（Dock / Finder / Touch ID 等）
    └── homebrew.nix          # Homebrew パッケージ管理
```

## 使用ツール

| ツール | 用途 |
|---|---|
| [nix-darwin](https://github.com/LnL7/nix-darwin) | macOS のシステム設定を宣言的に管理 |
| [home-manager](https://github.com/nix-community/home-manager) | ユーザー環境（パッケージ・dotfiles）を管理 |
| [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) | Homebrew パッケージを Nix で宣言的に管理 |

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
```

### 3. ホスト名の確認・変更

```bash
scutil --get LocalHostName
```

`flake.nix` と `nix-darwin/configuration.nix` の `hostname` / `networking.hostName` を実際のホスト名に合わせて変更する。

### 4. nix-darwinの初回インストール

```bash
cd ~/.nix-config
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .
```

## 日常的な使い方

### 設定変更の反映

```bash
cd ~/.nix-config
sudo darwin-rebuild switch --flake .
```

### パッケージ・ツールのバージョン更新

```bash
cd ~/.nix-config
nix flake update
sudo darwin-rebuild switch --flake .
```

### ロールバック

```bash
sudo darwin-rebuild --rollback
```

## 動作環境

- macOS 15 (Sequoia)
- Apple Silicon (aarch64-darwin)
