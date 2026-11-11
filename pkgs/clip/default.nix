{ pkgs }:
# AppKit の NSPasteboard を JXA から直接叩くので、Swift のツールチェーンを取り込まずに macOS 標準の osascript だけで動かす。
pkgs.writeTextFile {
  name = "clip";
  # 本体は単体で編集・実行できるよう .js として分け、ここでは読み込んで配置するだけにする。
  text = builtins.readFile ./clip.js;
  # シバンの /usr/bin/osascript で直接起動できるよう実行ビットを立てる。
  executable = true;
  # home.packages から PATH に載るよう bin 配下に置く。
  destination = "/bin/clip";
  # osascript と AppKit に依存するため、macOS 以外のホストへ誤って入らないようにする。
  meta = with pkgs.lib; {
    description = "Copy a file to the macOS clipboard: text as text, images as image data, anything else as the file itself";
    mainProgram = "clip";
    platforms = platforms.darwin;
  };
}
