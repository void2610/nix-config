# ghq + fzf launcher
# 使い方: g
#   j/k で移動、space で確定、q/esc でキャンセル
# 各リポジトリの状態 (dirty / ahead / behind / branch) を表示する。
# 状態取得は xargs -P で並列化、untracked は無視して高速化している。

g() {
  local red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' gray=$'\e[90m' reset=$'\e[0m'
  local listing selected repo_path

  # ghq 管理外の追加リポジトリ (存在するもののみ採用)
  local -a extra_repos
  local p
  for p in "$HOME/dotfiles" "$HOME/nix-config"; do
    [[ -d $p/.git ]] && extra_repos+=("$p")
  done

  listing=$(
    { ghq list -p; printf '%s\n' "${extra_repos[@]}"; } \
      | grep -vE '/(\.venv|venv|node_modules|vendor|\.tox|\.pixi|\.cargo|target|Pods|Packages|site-packages)/' \
      | xargs -P 16 -I {} zsh -c '
          repo=$1; R=$2; G=$3; Y=$4; W=$5; E=$6
          br=$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || echo "(detached)")
          ws=$(git -C "$repo" status --porcelain --untracked-files=no 2>/dev/null)
          if [[ -n $ws ]]; then
            n=$(printf "%s\n" "$ws" | wc -l | tr -d " ")
            d="${R}*${n}${E}"
          else
            d="${W}.${E}"
          fi
          if git -C "$repo" rev-parse --abbrev-ref "@{u}" >/dev/null 2>&1; then
            a=$(git -C "$repo" rev-list --count "@{u}..HEAD" 2>/dev/null)
            b=$(git -C "$repo" rev-list --count "HEAD..@{u}" 2>/dev/null)
            if (( a > 0 )); then ac="${G}↑${a}${E}"; else ac="${W}↑0${E}"; fi
            if (( b > 0 )); then bc="${Y}↓${b}${E}"; else bc="${W}↓0${E}"; fi
          else
            ac="${W}↑-${E}"
            bc="${W}↓-${E}"
          fi
          printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$d" "$ac" "$bc" "${repo:t}" "$br" "$repo"
        ' _ {} "$red" "$green" "$yellow" "$gray" "$reset"
  )

  selected=$(printf "%s\n" "$listing" \
    | sort -t $'\t' -k 4 \
    | column -t -s $'\t' \
    | fzf --ansi \
        --with-nth ..-2 \
        --preview "git -C {-1} -c color.status=always status -sb 2>/dev/null; echo; eza -la --icons --color=always {-1} 2>/dev/null || ls -la {-1}" \
        --preview-window=right:55%:wrap \
        --bind 'j:down,k:up,space:accept,q:abort') || return

  repo_path=$(printf '%s' "$selected" | awk '{print $NF}')
  [[ -n $repo_path ]] && cd "$repo_path"
}
