# melchior/ （nix-darwin）

[Melchior](https://github.com/AKARI-Inc/melchior) の C++ ビルドに必要な Homebrew パッケージを定義する。
`work-dev` ホストのみがインポートする。

## 管理パッケージ

| パッケージ | 用途 |
|---|---|
| `assimp` | 3D モデル読み込み・書き出し |
| `bullet` | 物理シミュレーション |
| `glew` | OpenGL 拡張 |
| `glfw` | ウィンドウ・入力管理 |
| `glm` | 数学ライブラリ |
| `jsoncpp` | JSON 処理 |
| `opencv` | 画像処理 |
| `pcl` | 点群処理 |
| `pkg-config` | ビルド時のパス解決 |
| `zstd` | 圧縮 |

## cmake での使い方

Homebrew パッケージは cmake が自動検索する（macOS では `/opt/homebrew` がデフォルト検索パス）。

```bash
cmake .. -GNinja \
  -DMELCHIOR_EXAMPLES=ON \
  -DMELCHIOR_BINDING=ON \
  -DPython_EXECUTABLE=$(which python3.12)
```

Python 依存については `home-manager/modules/melchior/` を参照。
