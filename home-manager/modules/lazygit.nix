{ pkgs, ... }:
let
  # ステージ済み diff から claude でコミットメッセージを生成し、nvim で編集してコミットするスクリプト。
  # 実装は lazygit-llm-commit-msg.sh に分離。
  llmCommitMsg = pkgs.writeShellScriptBin "lazygit-llm-commit-msg" (builtins.readFile ./lazygit-llm-commit-msg.sh);
in
{
  home.packages = [ llmCommitMsg ];

  programs.lazygit = {
    enable = true;
    settings = {
      # output = "terminal" のサブプロセス終了後に出る
      # 「Press enter to return to lazygit」の確認を省く。
      promptToReturnFromSubprocess = false;
      # loadingText 表示時のスピナーが速すぎるので、回転を緩める（デフォルト 50ms → 100ms）。
      gui.spinner.rate = 200;
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
        # `C` を上書きし、ステージ済み diff から claude でコミットメッセージを生成して即コミットする。
        # 別ウィンドウ（terminal サブプロセスや nvim）を出さず、生成中は loadingText のスピナーを表示する。
        # 生成メッセージを編集したい場合は、コミット後に `r`（reword）で内蔵パネルから直す。
        {
          key = "C";
          context = "files";
          description = "Commit (LLM-generated message)";
          loadingText = "Generating commit message with claude...";
          command = "lazygit-llm-commit-msg";
          output = "log";
        }
      ];
    };
  };
}
