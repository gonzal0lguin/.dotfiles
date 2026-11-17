# fzf: key bindings (ctrl-t files, ctrl-r history) + completion (**<tab>).
(( $+commands[fzf] )) || return 0

# fzf >= 0.48 ships its own zsh integration; older apt builds keep it in /usr/share
if fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
else
  for _f in /usr/share/doc/fzf/examples/{key-bindings,completion}.zsh; do
    [[ -r $_f ]] && source $_f
  done
  unset _f
fi

if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded --info=inline ${FZF_THEME_OPTS:-}"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || ls -la {}'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap"

# Alt+C -> smart_cd (functions.zsh) instead of fzf's plain cd widget
bindkey '\ec' smart_cd_widget
