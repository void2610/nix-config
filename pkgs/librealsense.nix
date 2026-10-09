{ pkgs }:
# nixpkgs 版は Linux 専用の v4l-utils を参照して darwin で評価エラーになるため、darwin でだけ Linux 専用部分を外す。
if !pkgs.stdenv.hostPlatform.isDarwin then
  pkgs.librealsense
else
  (pkgs.librealsense.override {
    # udev 用スクリプトの wrapProgram でしか使わないので、参照が残れば評価時に気付けるよう null にする。
    v4l-utils = null;
  }).overrideAttrs
    (old: {
      # Linux で libstdc++ を明示リンクするための依存で、clang + libc++ の darwin では GCC 一式のビルドを招くだけなので外す。
      buildInputs = builtins.filter (p: p != pkgs.gcc.cc.lib) old.buildInputs;

      # macOS に udev はないので、find_package 用の include パス修正だけを upstream の postInstall から残す。
      postInstall = ''
        substituteInPlace $out/lib/cmake/realsense2/realsense2Targets.cmake \
          --replace-fail "\''${_IMPORT_PREFIX}/include" "$dev/include"
      '';
    })
