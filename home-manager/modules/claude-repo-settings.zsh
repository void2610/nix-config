# settings.local.json は git 管理外なので、リポジトリ固有の個人設定は $CLAUDE_REPO_SETTINGS_DIR/<owner>/<name>.json に置いて --settings で渡す
claude() {
  local url repo
  url=$(git remote get-url origin 2>/dev/null)
  # worktree でも同じ origin を指すので、clone の場所や worktree に関わらず同じ設定になる
  [[ $url =~ '[:/]([^/:]+/[^/]+)$' ]] && repo=${match[1]%.git}

  local settings="$CLAUDE_REPO_SETTINGS_DIR/$repo.json"
  if [[ -n $repo && -f $settings && ${argv[(I)--settings]} -eq 0 ]]; then
    command claude --settings "$settings" "$@"
  else
    command claude "$@"
  fi
}
