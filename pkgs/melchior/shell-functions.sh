# 以後の `cmake` / `ninja` は wrapper が優先される。
export PATH="$MELCHIOR_REPO/.nix-melchior/bin:$PATH"

# 開発 shell の中では `b` だけで起動に必要な主要ターゲットまで揃うようにする。
# `melchior_main` と `toadflax` に加えて `ifc` も同時に更新し、実行直前に
# 補助バイナリだけ古いまま残って挙動がずれる事故を防ぐため。
b() {
  cd "$MELCHIOR_REPO/build" || return 1
  ninja melchior_main toadflax ifc -j8 && ./melchior_main
}
