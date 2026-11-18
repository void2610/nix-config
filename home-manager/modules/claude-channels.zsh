# --channels は設定ファイルに書けず起動フラグでしか渡せないため、リポジトリごとに channel プラグインの有効化と --channels をここで渡す

# プラグインはユーザー設定で無効にし、ここに書いたリポジトリでだけ有効にする。他のセッションまで同じ Bot に繋がるのを防ぐため
typeset -gA CLAUDE_CHANNEL_REPOS=(
  void2610-org/color-recollection "discord@claude-plugins-official"
)

claude() {
  local url repo
  url=$(git remote get-url origin 2>/dev/null)
  # worktree でも同じ origin を指すので、clone の場所や worktree に関わらず同じ設定になる
  [[ $url =~ '[:/]([^/:]+/[^/]+)$' ]] && repo=${match[1]%.git}

  local -a plugins=(${=CLAUDE_CHANNEL_REPOS[$repo]})
  if (( ${#plugins} == 0 || ${argv[(I)--channels]} )); then
    command claude "$@"
    return
  fi

  local settings
  settings=$(jq -cn '{enabledPlugins: ($ARGS.positional | map({(.): true}) | add)}' --args "${plugins[@]}")
  command claude --settings "$settings" --channels "${plugins[@]/#/plugin:}" "$@"
}
