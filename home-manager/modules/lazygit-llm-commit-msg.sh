# ステージ済み diff から claude で1行コミットメッセージを生成し、そのままコミットするスクリプト。
# lazygit の customCommand から output=log + loadingText 付きで呼ばれ、
# 別ウィンドウ（terminal サブプロセスや nvim）を出さずに lazygit 内で完結させる。
# 生成メッセージを編集したい場合は、コミット後に lazygit の `r`（reword）で直す。
set -eu

# ステージ済みの変更が無ければコミットしない。
if git diff --cached --quiet; then
  echo 'ステージ済みの変更がありません。' >&2
  exit 1
fi

# 英語の type prefix（feat:/fix: 等）を付けた Conventional Commits 形式で、本文は日本語で生成する。
msg=$(git diff --cached | claude -p 'Write a concise one-line git commit message summarizing the staged changes. Follow the Conventional Commits format with an English type prefix (feat:, fix:, refactor:, docs:, chore:, etc.) but write the description in Japanese. Output only the message text, no surrounding quotes or explanation.' | head -n1)

# 生成に失敗（空出力）した場合はコミットせず終了する。
if [ -z "$msg" ]; then
  echo 'コミットメッセージの生成に失敗しました。' >&2
  exit 1
fi

git commit -m "$msg"
