{
  programs.lazygit = {
    enable = true;
    settings = {
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
      ];
    };
  };
}
