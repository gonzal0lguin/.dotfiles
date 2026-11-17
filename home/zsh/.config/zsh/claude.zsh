# Claude Code helpers.
(( $+commands[claude] )) || return 0

# When the auto-compact plugin is enabled (install.sh asks), run claude inside
# its own tmux server so the plugin can type /compact into claude's pane.
if [[ $(sed -n 's/^CLAUDE_TMUX_WRAPPER=//p' $XDG_CONFIG_HOME/dotfiles/config 2>/dev/null) == yes ]]; then
  claude() {
    if [[ -n $TMUX ]] || (( ! $+commands[tmux] )); then
      command claude "$@"
    else
      # one quoted string, so several arguments survive the trip through tmux
      command tmux -L claude -f $XDG_CONFIG_HOME/tmux/claude.conf \
        new-session -s "cc-$$-$RANDOM" "command claude ${(j: :)${(q)@}}"
    fi
  }
fi
