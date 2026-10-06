# darwin / linux 双方の home-manager から import する共通 tmux 設定。
# プラットフォーム差分 (ログインシェル・クリップボード連携) だけを引数で受け取る。
{ shell, copyCommand }:
{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    prefix = "C-b";
    baseIndex = 1;
    inherit shell;
    terminal = "screen-256color";
    # nvim の autoread / カーソル形状復元にフォーカスイベントの伝播が要る
    focusEvents = true;
    # デフォルト 500ms だと nvim の <Esc> が体感で引っかかる
    escapeTime = 10;
    historyLimit = 50000;
    aggressiveResize = true;
    plugins = with pkgs.tmuxPlugins; [
      pain-control
      resurrect
      continuum
      sensible
      urlview
      copycat
      yank
      tmux-fzf
      extrakto
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-plugins "battery cpu-usage ram-usage time"
          set -g @dracula-show-powerline true
          set -g @dracula-show-left-sep ""
          set -g @dracula-show-right-sep ""
          set -g @dracula-show-left-icon session
          set -g @dracula-left-icon-padding 2
          set -g @dracula-show-location false
          set -g @dracula-show-fahrenheit false
          set -g @dracula-show-timezone false
          set -g @dracula-show-flags true
          set -g @dracula-military-time true
        '';
      }
    ];
    extraConfig = ''
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e'"
      bind | split-window -h
      bind - split-window -v

      bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel '${copyCommand}'

      # ウィンドウを閉じても番号を詰めて連番を保つ
      set -g renumber-windows on
      set -g display-time 2000
      set -g status-interval 5
      set -g set-clipboard on

      bind r source-file ~/.config/tmux/tmux.conf \; display "tmux.conf reloaded"
      bind C-b last-window

      set -g terminal-overrides 'xterm:colors=256'
      set -g @continuum-restore 'on'
      set -g @continuum-boot 'off'
    '';
  };
}
