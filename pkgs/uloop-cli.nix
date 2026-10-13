{ pkgs }:
let
  # V3 パッケージの Unity プロジェクトは V2 の npm CLI では tools.json を読めず起動に失敗するため、V3 のネイティブ dispatcher を固定する。
  version = "3.8.2";

  # 配布物がアーキテクチャ別のため、どのホストでも同じ derivation で入るよう両方の公式 .sha256 を並べる。
  assets = {
    aarch64-darwin = {
      name = "uloop-dispatcher-darwin-arm64.tar.gz";
      sha256 = "a790ebe8109cf00ef8ab19732dd8388f03e9d81ffb8fd575c0e38a4886e4b899";
    };
    x86_64-darwin = {
      name = "uloop-dispatcher-darwin-amd64.tar.gz";
      sha256 = "83accc927e63bdc53c9f6c8318bfc392930e368bfca9c88ddff4fadcd444fec8";
    };
  };
  asset = assets.${pkgs.stdenv.hostPlatform.system}
    or (throw "uloop: ${pkgs.stdenv.hostPlatform.system} 向けの dispatcher は未定義");
in
pkgs.stdenvNoCC.mkDerivation {
  # Home Manager 側の参照名 (uloopCli) と揃えるため pname は従来のまま据え置く。
  pname = "uloop-cli";
  inherit version;

  # GitHub Release のタグ dispatcher-v<version> に置かれた公式バイナリを取得し、ハッシュで再現性を固定する。
  src = pkgs.fetchurl {
    url = "https://github.com/hatayama/unity-cli-loop/releases/download/dispatcher-v${version}/${asset.name}";
    inherit (asset) sha256;
  };

  # アーカイブ直下に uloop バイナリが 1 つだけ入る形式なので、展開先をそのまま作業ディレクトリにする。
  sourceRoot = ".";

  # 配布済みバイナリを置くだけなのでビルド工程は不要。
  dontConfigure = true;
  dontBuild = true;

  # Apple Silicon では署名済みバイナリを strip すると署名が壊れて起動時に kill されるため、fixup を丸ごと止める。
  dontStrip = true;
  dontFixup = true;

  # dispatcher 本体だけを bin に配置する。プロジェクトごとの runner は実行時に dispatcher がユーザーキャッシュへ取得する。
  installPhase = ''
    runHook preInstall
    install -Dm755 uloop $out/bin/uloop
    runHook postInstall
  '';

  # Darwin ホスト向けの CLI としてメタデータを付け、Home Manager から扱いやすくする。
  meta = with pkgs.lib; {
    description = "Native dispatcher CLI for Unity CLI Loop (uLoopMCP V3)";
    homepage = "https://github.com/hatayama/unity-cli-loop";
    license = licenses.mit;
    mainProgram = "uloop";
    platforms = builtins.attrNames assets;
  };
}
