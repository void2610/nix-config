# ステージ済み diff から claude でコミットメッセージを生成し、nvim で編集してコミットするスクリプト。
# 生成中はスピナーを表示してフリーズに見えないようにする。
set -eu

# 前回までの実行ログ（スクロールバック含む）を消して画面をまっさらにする。
printf '\033[2J\033[3J\033[H'

# ステージ済みの変更が無ければ、生成するものが無いので即終了する。
if git diff --cached --quiet; then
  echo 'ステージ済みの変更がありません。' >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# claude をバックグラウンドで実行し、その間スピナーを回す。
( git diff --cached | claude -p 'Write a concise one-line git commit message summarizing the staged changes. Follow the Conventional Commits format with an English type prefix (feat:, fix:, refactor:, docs:, chore:, etc.) but write the description in Japanese. Output only the message text, no surrounding quotes or explanation.' | head -n1 > "$tmp" ) &
pid=$!
spin='-\|/'
i=0
while kill -0 "$pid" 2>/dev/null; do
  i=$(( (i + 1) % 4 ))
  printf '\rGenerating commit message with claude... %s' "${spin:$i:1}"
  sleep 0.1
done
# バックグラウンドジョブの終了ステータスを拾う（set -e でも捕捉できるよう if で受ける）。
if wait "$pid"; then
  status=0
else
  status=$?
fi
printf '\r\033[K'

# claude が失敗、または空メッセージしか返さなかった場合は、
# フリーズせず空のままエディタを開いて手動入力にフォールバックする。
if [ "$status" -ne 0 ] || [ ! -s "$tmp" ]; then
  echo 'コミットメッセージの生成に失敗しました。手動で入力してください。' >&2
  git commit -e
  exit
fi

# 生成メッセージをプリフィルした状態で nvim を開き、編集・保存でコミット。
git commit -e -F "$tmp"
