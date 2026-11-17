# Tool integrations that should load last.

(( $+commands[zoxide] ))   && eval "$(zoxide init zsh)"     # z <dir>, zi = interactive
(( $+commands[direnv] ))   && eval "$(direnv hook zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"
