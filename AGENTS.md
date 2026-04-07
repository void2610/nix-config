# AGENTS

## 最重要事項

- すべての設定箇所にコメントを書くこと。
- 1 つの設定ブロックを追加・変更するたびに、その直前または同じ文脈にコメントを置くこと。
- コメントは日本語で書くこと。
- コメントは「何をしているか」だけでなく、「なぜその設定が必要か」が分かる内容にすること。
- コメント不足のまま設定追加や構造変更をしないこと。

## 変更方針

- `flake.nix` は薄く保ち、構成の組み立ては `nix-darwin/` や `home-manager/` 配下に逃がす。
- ホスト固有の値は `nix-darwin/hosts/` に寄せ、profile と実ホスト名を混同しない。
- `server` 専用の設定は `work` や `game` に漏らさない。
- secrets や launchd など副作用のある設定は、適用対象ホストを明確に制限する。

## 運用メモ

- `darwin-rebuild switch --flake .` はホスト名と flake target 名が一致していないと失敗するため、通常は `.#work` や `.#server` を明示する。
- `work` 用の Melchior 環境は flake の `devShells` ではなく、`work` profile の Zsh 初期化からだけ入る。
