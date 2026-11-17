# Key bindings (emacs mode, like oh-my-zsh).

bindkey -e

# ↑/↓ search history for commands starting with what is typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search   '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search

bindkey '^[[1;5C' forward-word    # ctrl →
bindkey '^[[1;5D' backward-word   # ctrl ←
bindkey '^[[H' beginning-of-line  '^[OH' beginning-of-line  '^[[1~' beginning-of-line
bindkey '^[[F' end-of-line        '^[OF' end-of-line        '^[[4~' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[3;5~' kill-word       # ctrl delete
bindkey '^H' backward-kill-word   # ctrl backspace

# ctrl-x ctrl-e: edit the current command in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
