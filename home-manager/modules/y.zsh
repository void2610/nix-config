# yazi wrapper
# 使い方: y
# yazi 終了時のカレントディレクトリを zsh の cwd に反映する。
# yazi 公式推奨の launcher 実装。

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
