# nixpkgs の GLEW CMake config は macOS で余計な bare link を追加する。
# repo ローカルに config を複製し、その行だけ外して使う。
if [[ -d "$MELCHIOR_REPO/.nix-melchior/cmake/glew" ]]; then
  chmod -R u+w "$MELCHIOR_REPO/.nix-melchior/cmake/glew" || true
  rm -rf "$MELCHIOR_REPO/.nix-melchior/cmake/glew"
fi
mkdir -p "$MELCHIOR_REPO/.nix-melchior/cmake/glew"
cp @glewDev@/lib/cmake/glew/* "$MELCHIOR_REPO/.nix-melchior/cmake/glew/"
chmod -R u+w "$MELCHIOR_REPO/.nix-melchior/cmake/glew"
python3 - <<'EOF'
from pathlib import Path
import re

path = Path("@glewConfigPath@")
text = path.read_text()
text = re.sub(
    r"\nset_target_properties\(GLEW::GLEW\$\{_glew_target_postfix\} PROPERTIES.*?\n\)\n",
    "\n",
    text,
    flags=re.S,
)
path.write_text(text)
EOF
export MELCHIOR_GLEW_DIR="$MELCHIOR_REPO/.nix-melchior/cmake/glew"
