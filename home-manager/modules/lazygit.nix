{ pkgs, ... }:
let
  # ステージ済み diff から claude でコミットメッセージを生成し、nvim で編集してコミットするスクリプト。
  # 生成中はスピナーを表示してフリーズに見えないようにする。
  llmCommitMsg = pkgs.writeShellScriptBin "lazygit-llm-commit-msg" ''
    set -eu
    # 前回までの実行ログ（スクロールバック含む）を消して画面をまっさらにする。
    printf '\033[2J\033[3J\033[H'
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT

    # claude をバックグラウンドで実行し、その間スピナーを回す。
    ( git diff --cached | claude -p 'Write a concise one-line git commit message summarizing the staged changes. Output only the message text, no surrounding quotes or explanation.' | head -n1 > "$tmp" ) &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 "$pid" 2>/dev/null; do
      i=$(( (i + 1) % 4 ))
      printf '\rGenerating commit message with claude... %s' "''${spin:$i:1}"
      sleep 0.1
    done
    wait "$pid"
    printf '\r\033[K'

    # 生成メッセージをプリフィルした状態で nvim を開き、編集・保存でコミット。
    git commit -e -F "$tmp"
  '';
in
{
  home.packages = [ llmCommitMsg ];

  programs.lazygit = {
    enable = true;
    settings = {
      # output = "terminal" のサブプロセス終了後に出る
      # 「Press enter to return to lazygit」の確認を省く。
      promptToReturnFromSubprocess = false;
      customCommands = [
        # `c` を上書きし、空のコミットメッセージ入力欄を出す。
        # 空のままエンターすると、選択中ファイルの git status を見て
        # 新規追加なら "create <file>"、削除なら "delete <file>"、それ以外は "update <file>" でコミットする。
        # 何か入力すればその文面がそのまま使われる。
        {
          key = "c";
          context = "files";
          description = "Commit (empty = create/delete/update <file>)";
          prompts = [
            {
              type = "input";
              title = ''{{ if .SelectedFile }}Commit {{ .SelectedFile.Name }} (empty = auto){{ else }}Commit message{{ end }}'';
              key = "Msg";
            }
          ];
          command = ''
            msg="{{ .Form.Msg }}"
            if [ -z "$msg" ]; then
              files=$(git diff --cached --name-only)
              count=$(printf '%s\n' "$files" | grep -c .)
              if [ "$count" -eq 1 ]; then
                st=$(git status --porcelain -- "$files" | cut -c1-2)
                case "$st" in
                  A*) verb=create ;;
                  *D*) verb=delete ;;
                  *)  verb=update ;;
                esac
                msg="$verb $files"
              fi
            fi
            if [ -z "$msg" ]; then
              echo "commit message required (multiple staged files)" >&2
              exit 1
            fi
            git commit -m "$msg"
          '';
        }
        # `C` を上書きし、ステージ済み diff から claude でコミットメッセージを生成する。
        # 生成中はスピナーを表示し、生成後に nvim で編集してコミットする。
        {
          key = "C";
          context = "files";
          description = "Commit (LLM-generated message)";
          command = "lazygit-llm-commit-msg";
          output = "terminal";
        }
      ];
    };
  };
}
