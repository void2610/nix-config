# home-manager/modules/

全プロファイル共通のユーザー環境モジュール群。

## ファイル一覧

| ファイル / ディレクトリ | 内容 |
|---|---|
| `packages.nix` | 共通 CLI / 開発パッケージ |
| `git.nix` | Git 設定（user・署名・SSH エイリアス） |
| `shell.nix` | Zsh・starship・direnv・fzf・zoxide |
| `tmux.nix` | Tmux プラグイン・Dracula テーマ・セッション復元 |
| `melchior/` | Melchior Python 依存（work profile のみ） |

詳細は親ディレクトリの [../README.md](../README.md) を参照。
