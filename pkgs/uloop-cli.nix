{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  # npm 配布物の実体名を固定する。
  # ラッパー生成先や Home Manager 側の参照と一致させ、名前ずれで更新時に壊れないようにする。
  pname = "uloop-cli";
  # Unity CLI Loop の新機能と既存バグ修正を取り込むため、npm の最新公開版を明示的に固定する。
  version = "2.0.4";

  # npm レジストリの tarball を直接取得する。
  # lockfile を持たない単体パッケージなので、URL とハッシュを Nix 側で固定して再現性を保つ。
  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/uloop-cli/-/uloop-cli-${version}.tgz";
    hash = "sha512-HfuQ1b1o7gGF0c5Gi4aAh8Eexs69ZoD357+CnNdEKNnbquwz4h3oi8KWK8UIJDAiwKSp2dfcaWZsb/oMcHAc6w==";
  };

  # Node 実行用の薄いラッパーだけを作る構成なので、ビルド時依存は makeWrapper に絞る。
  # 余計な依存を増やさず、壊れる要因を最小限にするため nativeBuildInputs を明示する。
  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  # 取得した tarball をそのまま配置して使うため、通常のビルド工程は不要にする。
  # npm パッケージの内容を変換せず扱い、更新時の差分を読みやすく保つために無効化している。
  dontBuild = true;

  # パッケージ本体を Node モジュール配置にコピーし、CLI エントリポイントへラッパーを張る。
  # npm インストーラに依存せず Nix ストア内だけで完結させ、実行環境を安定させるための手順。
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/uloop-cli
    cp -r . $out/lib/node_modules/uloop-cli

    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/uloop \
      --add-flags "$out/lib/node_modules/uloop-cli/dist/cli.bundle.cjs"

    runHook postInstall
  '';

  # Darwin ホスト向けの社内利用 CLI としてメタデータを付ける。
  # 対応プラットフォームや既定コマンド名を明示し、Home Manager から扱いやすくするための定義。
  meta = with pkgs.lib; {
    description = "CLI tool for Unity Editor communication via Unity CLI Loop";
    homepage = "https://github.com/hatayama/uLoopMCP#readme";
    license = licenses.mit;
    mainProgram = "uloop";
    platforms = platforms.darwin;
  };
}
