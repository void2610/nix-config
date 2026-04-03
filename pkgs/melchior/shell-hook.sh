# Melchior 用 shellHook の入口。
# 詳細は役割ごとの小さいファイルへ分割し、ここでは読む順だけを管理する。
source "@envScript@"
source "@glewScript@"
source "@wrappersScript@"
source "@sitePackagesScript@"
source "@shellFunctionsScript@"

echo "Melchior Nix shell ready"
echo "  python: $MELCHIOR_BUILD_PYTHON_EXECUTABLE"
echo "  cmake : $MELCHIOR_REPO/.nix-melchior/bin/cmake"
echo "  ninja : $MELCHIOR_REPO/.nix-melchior/bin/ninja"
