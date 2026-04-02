# pkgs/

nixpkgs に存在しないパッケージのカスタム Nix 定義。

## ファイル一覧

| ファイル | パッケージ | 内容 |
|---|---|---|
| `claude-code-ui.nix` | `claudeCodeUi` | `@siteboon/claude-code-ui` を npm から直接ビルド |
| `claude-code-ui-package-lock.json` | - | ビルド時に使用する lock ファイル |

## 使い方

`home-manager/modules/packages.nix` でインポートして使用している。

```nix
claudeCodeUi = import ../../pkgs/claude-code-ui.nix { inherit pkgs; };
```

## 新しいパッケージを追加するとき

nixpkgs にないパッケージや独自ビルドが必要な場合にこのディレクトリに追加する。
