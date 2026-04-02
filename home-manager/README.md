# home-manager/

ユーザー環境設定層。CLI パッケージ・シェル・Git・エディタ等を管理する。

## ディレクトリ構成

```
home-manager/
├── users/      # ユーザー定義（モジュールの組み合わせ）
├── modules/    # 全プロファイル共通のユーザーモジュール
└── profiles/   # プロファイル別の差分
```

---

## users/

### default.nix
全ホスト共通のユーザー設定。`modules/` 以下を全てインポートしている。

- `home.stateVersion = "24.11"`
- docker-compose の Homebrew 版を `~/.docker/cli-plugins/` にリンク

---

## modules/

### packages.nix
全プロファイル共通の CLI / 開発パッケージ。

`age`, `clang-tools`, `cmake`, `colima`, `docker-client`, `docker-compose`,
`dotnet-sdk`, `fd`, `gh`, `neovim`, `nodejs_22`, `qemu`, `sops`, `yarn`

カスタム:
- `neofetch`: GitHub から直接ビルド（nixpkgs 版が deprecated のため）
- `claudeCodeUi`: `pkgs/claude-code-ui.nix` で定義した npm パッケージ

### git.nix
Git 設定。

- `user.name`: `void2610`
- `user.email`: `contact@void2610.dev`
- 署名: `openpgp`
- `git@github:` を `id_github_rsa` 経由にリダイレクト

### shell.nix
Zsh とシェル環境の設定。

**有効化するプログラム**:
- `direnv` + `nix-direnv`
- `fzf`
- `starship`
- `zoxide` (`cd` を置換)

**PATH に追加**:
`~/.local/bin`, `/opt/homebrew/{bin,sbin}`, `~/Documents`, `~/.yarn/bin`

**エイリアス**:

| エイリアス | 内容 |
|---|---|
| `ur` | `uv run python` |
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza -la --icons --group-directories-first` |
| `tree` | `eza --tree --icons` |
| `bell` | macOS サウンド再生 |
| `colima` | `SSH_AUTH_SOCK=` を付けて起動（macOS 25.4 以降の SSH エージェントブロック回避） |

### tmux.nix
Tmux の設定。Dracula テーマ + 各種プラグイン。

**プラグイン**: `pain-control`, `resurrect`, `continuum`, `sensible`,
`urlview`, `copycat`, `yank`, `tmux-fzf`, `extrakto`, `dracula`

**ステータスバー表示**: battery, cpu-usage, ram-usage, time

**セッション復元**: `continuum` で自動復元 ON

### melchior/ （work profile のみ）

→ [modules/melchior/README.md](modules/melchior/README.md) を参照

---

## profiles/

ホスト間の差分のみを定義する。共通設定は `modules/` に置く。

| ファイル | 内容 |
|---|---|
| `game.nix` | 現状は空（game は基本設定のみ） |
| `work.nix` | `modules/melchior/` をインポート |
| `server.nix` | 現状は空（server は基本設定のみ） |
