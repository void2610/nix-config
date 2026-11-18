# --channels は設定ファイルに書けず起動フラグでしか渡せないため、プロジェクトの settings.local.json で有効にした channel プラグインをここで渡す
claude() {
  local root settings
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  settings="$root/.claude/settings.local.json"

  local -a channels
  if [[ -f $settings && ${argv[(I)--channels]} -eq 0 ]]; then
    # Anthropic の allowlist に載る channel プラグインだけが --channels を受け付ける
    channels=(${(f)"$(jq -r '
      (.enabledPlugins // {}) | to_entries[]
      | select(.value == true)
      | select(.key | test("^(discord|telegram|imessage)@claude-plugins-official$"))
      | "plugin:" + .key
    ' "$settings" 2>/dev/null)"})
  fi

  if (( ${#channels} )); then
    command claude --channels "${channels[@]}" "$@"
  else
    command claude "$@"
  fi
}
