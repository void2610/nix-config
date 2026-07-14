{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    prefix = "C-b";
    baseIndex = 1;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
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

      # Wayland / X11 をセッション環境から実行時判定してクリップボードへコピーする。
      bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'if [ -n "$WAYLAND_DISPLAY" ]; then wl-copy; else xclip -selection clipboard -in; fi'

      set -g terminal-overrides 'xterm:colors=256'
      set -g @continuum-restore 'on'
      set -g @continuum-boot 'off'
    '';
  };
}
