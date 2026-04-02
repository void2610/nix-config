# nix-darwin/

macOS のシステム設定層。Homebrew・セキュリティ・macOS デフォルト等を管理する。

## ディレクトリ構成

```
nix-darwin/
├── hosts/          # ホスト固有の設定（ホスト名・ユーザー名等）
└── modules/        # 全ホスト共通のシステムモジュール
```

---

## hosts/

各ファイルはホスト固有の値のみを持つ。共通設定は `modules/` に置く。

| ファイル | ホスト名 | profile | 追加モジュール |
|---|---|---|---|
| `Macintosh.nix` | Macintosh | game | - |
| `game-dev.nix` | game-dev | game | - |
| `work-dev.nix` | PCmac24055 | work | `modules/melchior/` |
| `server-node.nix` | server-node | server | - |

---

## modules/

### base.nix
`defaults.nix` / `nix-core.nix` / `security.nix` / `secrets.nix` をまとめてインポートする中間層。
各ホストは `base.nix` と `homebrew.nix` だけを指定すれば共通設定が全て入る。

### defaults.nix
macOS の UI/UX デフォルト設定。

- Dock: 自動非表示、サイズ設定
- Finder: 隠しファイル表示・パスバー表示
- キーボード: キーリピート速度
- スクリーンセーバー: 自動ロック

### nix-core.nix
Nix の実験的機能（`nix-command`, `flakes`）を有効化。

### security.nix
Touch ID による `sudo` 認証を有効化。

### secrets.nix
sops-nix で `secrets/common.yaml` を復号して SSH 鍵を配置する。

| secrets キー | 配置先 |
|---|---|
| `ssh_config` | `~/.ssh/config` |
| `ssh_id_github_rsa` | `~/.ssh/id_github_rsa` |
| `ssh_id_rsa` | `~/.ssh/id_rsa` |
| `ssh_mirai_server` | `~/.ssh/mirai-server` |

> **注意**: sops-nix がシンボリックリンクとして配置するとSSH秘密鍵末尾の改行が失われる問題がある。
> そのため、アクティベーションスクリプトでシンボリックリンクを実ファイルに変換している。

### homebrew.nix
Homebrew パッケージをプロファイル別に宣言的管理する。

**全プロファイル共通 (commonBrews)**:
`eza`, `ninja`, `fzf`, `jq`, `ripgrep`, `zoxide`, `uv`, `go`, `git-lfs`, `ffmpeg` 等

**全プロファイル共通 (desktopCasks)**:
`claude-code`, `warp`, `zed`, `visual-studio-code`, `arc`, `bitwarden`, `raycast`, `karabiner-elements` 等

**profile 別**:

| profile | brews | casks |
|---|---|---|
| game | - | `discord`, `obs`, `rider`, `steam`, `unity-hub`, `affinity` |
| work | - | `blender`, `cloudcompare`, `freecad`, `google-chrome`, `zoom` |
| server | - | `unity-hub` |

### melchior/ （work-dev のみ）

→ [melchior/README.md](melchior/README.md) を参照
