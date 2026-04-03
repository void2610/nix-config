# 以後の `cmake` / `ninja` は wrapper が優先される。
export PATH="$MELCHIOR_REPO/.nix-melchior/bin:$PATH"

# 開発 shell の中では `b` だけでビルドして起動できるようにする。
b() {
  cd "$MELCHIOR_REPO/build" || return 1
  ninja melchior_main toadflax -j8 && ./melchior_main
}
