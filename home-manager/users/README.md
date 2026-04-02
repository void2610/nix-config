# home-manager/users/

ユーザー設定の定義。モジュールの組み合わせと `home.stateVersion` を管理する。

## ファイル一覧

| ファイル | 内容 |
|---|---|
| `default.nix` | 全ホスト共通ユーザー設定。`modules/` 以下を全てインポート |

## default.nix の役割

- `home.username` / `home.homeDirectory` の設定
- `home.stateVersion = "24.11"`
- `modules/packages.nix`, `git.nix`, `shell.nix`, `tmux.nix` のインポート
- docker-compose の Homebrew 版を `~/.docker/cli-plugins/` にリンク
